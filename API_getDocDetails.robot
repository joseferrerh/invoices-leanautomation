*** Settings ***
Documentation     HTTP API robot. Retrieves invoice details from DocDigitizer
...               response as JSON, access JSON properties, etc.).
Library           RPA.HTTP
Library           RPA.core.notebook
Library           RPA.JSON
Library           RPA.FileSystem
Library           OperatingSystem
Library           String
Library           Collections
Library           RPA.Robocorp.WorkItems
Resource          res_airtable.robot
Resource          res_docdigitizer.robot
Resource          res_creatio.robot


*** Tasks ***
Get Details from docDigit Invoice
    ${payload}=  Get Work Item Payload

    ${API_URL}    Create Session Airtable
    Create Session DocDigitizer

    Log To Console    ${payload}[documentID]

    ${resp}=    GET On Session    docdigitizer    /api/v1/documents/${payload}[documentID]

    Log    ${resp}
    Log    ${resp.json()}
    ${respDocument}    Set Variable    ${resp.json()}[document]
    Log    ${respDocument}[id]
    Log    ${respDocument}[annotations][data]

    # Sample Record ID: 0f058c3b-eb2b-4627-bf06-d6fdcf74600fg
    # The following comment is the old Get Request mode API Call
    # ${resp}     Get Request     airtable    ${API_URL}?maxRecords=1&filterByFormula=%7BdocumentID%7D%3D%27${payload}[documentID]%27&view=Grid%20view
    &{params}=    Create Dictionary
    ...    maxRecords=1
    ...    filterByFormula=documentID=${payload}[documentID]
    ${resp}     GET On Session     airtable    url=${API_URL}    params=${params}
    ${jsondata}=    set Variable    ${resp.json()}
    
    Log  ${resp}
    ${first_record_id}=    Get value from JSON    ${jsondata}    $.records[0].id
    Log  ${first_record_id}

    ${fields}=    Get value from JSON    ${jsondata}    $.records[0].fields
    Log  ${fields}

    ${resp}    Update Airtable Record    ${first_record_id}    ${respDocument}[annotations][data]
    Log    ${resp}

    # Check if the invoice origin is CREATIO 
    ${esCreatio}=    Run Keyword And Return Status       Dictionary Should Contain Key       ${fields}      urlCreatio
    # The folowing line can be uncommented if the Creatio functionality needs to be tested 
    # ${esCreatio}=    Set Variable    ${True}
    
    IF    ${esCreatio}
        Create Session Creatio
        ${resp}    POST Contents to Creatio    ${CREATIOINV_API_URL}    ${fields}[invoiceId]    ${respDocument}[annotations][data]
        Log    ${resp}
        Status Should Be    OK    ${resp}
        Log    ${resp.content}
        Should Be Equal As Strings    ${resp.status_code}    200
    END


*** Keywords ***
POST Contents to Creatio
    [Documentation]    This function do the POST to Creatio
    [Arguments]    ${url}    ${invoice}    ${data}
    Log    ${data}[document:financial-document:recipient_name]

    ${invoice_data}    Create Dictionary
    ...    process_id            1111
    ...    runprocess_id         ${EMPTY}
    ...    invoice_id            4d7356ae-dc1b-46c5-9acd-af04446cb40d
    ...    recipient_name        ${data}[document:financial-document:recipient_name]
    ...    recipient_tax_number  ${data}[document:financial-document:recipient_tax_number]
    ...    supplier_name         ${data}[document:financial-document:supplier_name]
    ...    supplier_tax_number   ${data}[document:financial-document:supplier_tax_number]
    ...    document_type         ${data}[document:financial-document:document_type]
    ...    document_identifier   ${data}[document:financial-document:document_identifier]
    ...    issue_date            ${data}[document:financial-document:issue_date]
    ...    due_date              ${data}[document:financial-document:due_date]
    ...    currency              ${data}[document:financial-document:currency]
    ...    amount_total          ${data}[document:financial-document:amount_total]
    ...    amount_tax_total      ${data}[document:financial-document:amount_tax_total]
    ...    amount_paid           ${data}[document:financial-document:amount_paid]
    ...    amount_rounding       ${data}[document:financial-document:amount_rounding]
    ...    amount_due            ${data}[document:financial-document:amount_due]


    # El POST a creatio se realiza a la siguiete URL 
    # ${resp}    POST        https://118762-crm-bundle.creatio.com/0/ServiceModel/RPARobocorpInvoice.svc/InvoiceResponse
    ${response}    POST On Session    creatio    /InvoiceResponse    json=${invoice_data}
    
    [Return]    ${response}
