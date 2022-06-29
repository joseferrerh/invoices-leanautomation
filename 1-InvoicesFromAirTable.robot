*** Settings ***
Documentation     Use this task if your users upload invoices directly to Airtable.
...               Those invoices are retrieved from Airtable, the PDF file is downloaded, and a request with that invoice file is then sent to DocDigitizer.
Library           RPA.HTTP
Library           RPA.core.notebook
Library           RPA.JSON
Library           RPA.FileSystem
Library           OperatingSystem
Library           String
Library           Collections
Resource          res_airtable.robot
Resource          res_docdigitizer.robot
#Suite Setup       Setup
#Suite Teardown    Teardown


*** Tasks ***
Read Invoices from AirTable

    ${API_URL}    Create Session Airtable
    Create Session DocDigitizer

    # Query the New invoices in AirTable
    # Those invoices has been manually uploaded by the user 

    # ${resp}     Get Request     airtable    ${API_URL}?maxRecords=100&filterByFormula=Status%3D"Todo"&sort%5B0%5D%5Bfield%5D=invoiceName
    &{params}=    Create Dictionary
    ...    maxRecords=100
    ...    filterByFormula=Status="Todo"
    ${resp}     GET On Session     airtable    url=${API_URL}    params=${params}
    ${jsondata}=    set Variable    ${resp.json()}
    
    ${invoices}    Set Variable    ${jsondata}[records]
    Log    ${invoices}
    Log    ${invoices}.length
    ${contador}     Get Length   ${invoices}
    
    @{all_invoices}=    Get values from JSON    ${jsondata}    $..invoiceName
    Log Many  ${all_invoices}
    Log Many  @{all_invoices}.length

    ${contador}     Get Length   ${all_invoices}

    FOR  ${invoice}    IN    @{invoices}
        # [Tags]    post
        # Get the attachment file from Airtable
        # Send it to docDigitizer
        ${idAirTable}     Set Variable    ${invoice}[id]
        ${invoiceName}    Get Attachment    ${invoice}
        Log    ${invoiceName}

        # The following line allows to test without sending data to DocDigitizer
        # It creates a fake response to test the entire flow
        # ${resp}    Convert String to JSON    {"detail": "Accepted", "status": 202, "task": {"created": "2022-04-08T00:14:37.641664", "id": "43917093-0633-4600-bbc7-c465d58cab4e", "status": "PENDING", "links": {"self": "/api/v1/tasks/43917093-0633-4600-bbc7-c465d58cab4e", "collection": "/api/v1/tasks"}}}
        # Send to DocDigitizer
        ${resp}    Send to DocDigitizer    ${invoiceName}
 

        Log    ${resp}
        #${respuesta}    Set Variable    ${resp.json()}
        ${task}    Set Variable    ${resp}[task]
        Log    ${task}[id] ${task}[created] ${task}[status]
    
        Sleep    10

        ${resp}=    GET On Session    docdigitizer    /api/v1/tasks/${task}[id]

        Log    ${resp}
        Log    ${resp.json()}

        # Aqui se intentaba leer el documento pero la mayor parte de las veces NO VIENE
        # Asi qe hay que crear otro STEP que interrogue las facturas con task y sin documento y actualice Airtable
        # ${respDocument}    Set Variable    ${resp.json()}[document]
        # Log    ${respDocument}[id]
        # Log    ${respDocument}[annotations][data]

        # Actualizamos Airtable
        # Pruebas realizadas un dia horrible que no funcionaba nada
        #${jsonFilaAir}     Set Variable    {"records":[{"id": "${all_ids[${i}]}", "fields":${json}, "typecast": true\}\]\}
        #${jsonFilaAir}     Set Variable    {"records":[{"fields":{"PlazoSolicitud": "\u00daltima convocatoria, hasta el 31 de diciembre de 2020. En espera de pr\u00f3xima convocatoria"}, "typecast": true\}\]\}
        #${jsonFilaAir}     Set Variable    {"fields":{"PlazoSolicitud": "\u00daltima convocatoria, hasta el 31 de diciembre de 2020. En espera de pr\u00f3xima convocatoria"}, "typecast": true\}

        &{row}=       Create Dictionary
        ...             taskID               ${task}[id]        

        ${json}            Convert JSON to String   ${row}
        ${jsonFilaAir}     Set Variable    {"records":[{\"id\": "${idAirTable}", \"fields\": {"Status": "New", "taskID": "${task}[id]"}}\]\}
        Log     ${jsonFilaAir}

        ${datos}=    Convert String to JSON     ${jsonFilaAir}

        Log     Update row in Airtable
        #${resp}=    Patch Request    Airtable    ${INVOICES_API_URL}/${idAirTable}    json=${datos}
        ${resp}=    PATCH On Session    Airtable    ${API_URL}    json=${datos}
        Should Be Equal As Strings    ${resp.status_code}    200

    END     

*** Keywords ***
Get Attachment
    [Arguments]    ${invoice}
    Log    ${invoice}
    ${jsonInvoice}    Set Variable    ${invoice}
    ${invoiceName}    Set Variable    ${jsonInvoice}[fields][invoiceName]
    ${targetfile}     Set Variable    temp${/}${invoiceName}.pdf 
    @{attachments}    Set Variable    ${jsonInvoice}[fields][Attachments]

    Log    ${attachments}
    Log    ${attachments}[0][url]
    Download    url=${attachments}[0][url]    target_file=${targetfile}    verify=True    overwrite=True

    [Return]    ${targetfile}
