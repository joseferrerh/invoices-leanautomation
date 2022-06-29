*** Settings ***
Documentation     Send Invoice to DocDigitizer. Save the relevant data in Airtable
Library           RPA.HTTP
Library           RPA.core.notebook
Library           RPA.JSON
Library           RPA.FileSystem
Library           OperatingSystem
Library           String
Library           Collections
Library           RPA.Robocorp.WorkItems
Library           base64File
Resource          res_airtable.robot
Resource          res_docdigitizer.robot


*** Tasks ***
Send Invoice to docDigit
    ${payload}=  Get Work Item Payload
    Log    ${payload}

    ${API_URL}    Create Session Airtable
    Create Session DocDigitizer

    Save File Base64    output${/}${payload}[invoiceName]    ${payload}[invoiceContent]

    ${file}=  Get File For Streaming Upload  output${/}${payload}[invoiceName]

    Sleep    5
    # &{files}=  Create Dictionary  files  ${payload}[invoiceName]
    &{files}=  Create Dictionary  
    ...    files    ${file}

    ${resp}=  Post On Session    docdigitizer  /api/v1/documents/annotate:financial-document  files=${files}

    ${respuesta}    Set Variable    ${resp.json()}
    ${task}    Set Variable    ${respuesta}[task]
    Log To Console    ${task}[id]
    Log To Console    ${task}[created]
    Log To Console    ${task}[status]

    Sleep    30

    ${resp}=    GET On Session    docdigitizer    /api/v1/tasks/${task}[id]
    Log    ${resp}
    Log    ${resp.json()}

    # This is to obtain Document ID but it is not always available
    #${respDocument}    Set Variable    ${resp.json()}[document]
    #Log    ${respDocument}[id]
    #Log    ${respDocument}[annotations][data]

    # The following call inserts the information in the Airtable repository
    # This is the old way, when a document ID was retrieved
    # ${resp}    Insert into Airtable    ${payload}[invoiceName]   ${task}[id]    ${respDocument}[id]    ${payload}[InvoiceId]    ${payload}[urlCreatio]
    ${resp}    Insert into Airtable    ${API_URL}    ${payload}[invoiceName]   ${task}[id]    ${payload}[invoiceId]    ${payload}[urlCreatio]
    #${jsondata}=    Set Variable    ${resp.json()}
    Log    ${resp}

