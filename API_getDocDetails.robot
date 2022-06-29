*** Settings ***
Documentation     HTTP API robot. Retrieves data from SpaceX API. Demonstrates
...               how to use RPA.HTTP (create session, get response, validate
...               response status, pretty-print, get response as text, get
...               response as JSON, access JSON properties, etc.).
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
Resource          res_creatio.robot
#Suite Setup       Setup
#Suite Teardown    Teardown


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

    # Localizar Registro 0f058c3b-eb2b-4627-bf06-d6fdcf74600fg
    # OJO que le he cambiado el numero. No es el del workitem!! Tiene una g mas
    #${resp}     Get Request     airtable    ${API_URL}?maxRecords=1&filterByFormula=%7BdocumentID%7D%3D%27${payload}[documentID]%27&view=Grid%20view
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

    #${supplierName}=    Get value from JSON    ${jsondata}    $.fields.supplierName
    #${urlCreatio}=    Get value from JSON    ${jsondata}    $.fields.urlCreatio
    #${fields}=    To Json    ${fields}

    ${resp}    Update Airtable Record    ${first_record_id}    ${respDocument}[annotations][data]
    #${jsondata}=    Set Variable    ${resp.json()}
    Log    ${resp}


    # Log    ${fields}[supplierName]
    #Log    ${fields}[urlCreatio] 
    ${esCreatio}=    Run Keyword And Return Status       Dictionary Should Contain Key       ${fields}      urlCreatio
    ${esCreatio}=    Set Variable    True
    
    IF    ${esCreatio}
        Create Session Creatio
        ${resp}    POST Contents to Creatio    ${CREATIOINV_API_URL}    ${fields}[invoiceId]    ${respDocument}[annotations][data]
        Log    ${resp}
        Status Should Be    OK    ${resp}
        Log    ${resp.content}
        Should Be Equal As Strings    ${resp.status_code}    200
    END


    @{all_ids}=    Get values from JSON    ${jsondata}    $..id
    Log Many  ${all_ids}
    Log Many  @{all_ids}






*** Keywords ***
POST Contents to Creatio
    [Arguments]    ${url}    ${invoice}    ${data}
    Log    En esta funcion hacemos el POST a Creatio
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

Read Invoices
    ${INVOICES_DIR}=   set variable  ${CURDIR}\\Invoices
    ${files}=  RPA.FileSystem.List files in directory  ${INVOICES_DIR}
    FOR    ${file}  IN  @{FILES}
        #[Tags]    post


        &{headers}=    Create Dictionary
        ...    Content-Type    multipart/form-data
        ...    Accept    application/octet-stream
        ...    Authorization    API_KEY a7d4228d-cdb5-421a-b5cc-9f0d228a87d2
        Create Session    docdigi    https://api.docdigitizer.com    verify=True  headers=&{headers}

        &{headersfiles}=    Create Dictionary
        ...    Content-Type    multipart/form-data;boundary\=----WebKitFormBoundary7MA4YWxkTrZu0gW
        ...    Accept    application/octet-stream
        ...    Authorization    API_KEY a7d4228d-cdb5-421a-b5cc-9f0d228a87d2
        ...    ----WebKitFormBoundary7MA4YWxkTrZu0gW
        ...    Content-Disposition    form-data; name="files"; filename="C:\TEMP\4043136189.pdf"
        ...    Content-Type    application/pdf
        ...    ----WebKitFormBoundary7MA4YWxkTrZu0gW

        ${resp}=    POST On Session    docdigi    /api/v1/documents/annotate:financial-document    headers=&{headersfiles}    
        

        #${file}=    To Json    ${resp.json()['files']['file']}
        ${respuesta}    Set Variable    ${resp.json()}
        # ${respuesta}    Convert String to Json   ${resp.json()}
        ${respuesta}    Set Variable    ${respuesta}[task]
        Log    ${respuesta}[id]
        Log    ${respuesta}[created]
        Log    ${respuesta}[status]

        #${resp}=    GET On Session    docdigi    /api/v1/tasks/

   END     


*** Keywords ***
Read Invoices Files
    ${INVOICES_DIR}=   set variable  ${CURDIR}\\Invoices
    ${files}=  RPA.FileSystem.List files in directory  ${INVOICES_DIR}
    FOR    ${file}  IN  @{FILES}
        #[Tags]    post


        &{headers}=    Create Dictionary
        ...    Content-Type    multipart/form-data
        ...    Accept    application/octet-stream
        ...    Authorization    API_KEY a7d4228d-cdb5-421a-b5cc-9f0d228a87d2
        Create Session    docdigi    https://api.docdigitizer.com    verify=True  headers=&{headers}

        #&{headersfiles}=    Create Dictionary
        #...    Content-Type    multipart/form-data;boundary\=----WebKitFormBoundary7MA4YWxkTrZu0gW
        #...    Accept    application/octet-stream
        #...    Authorization    API_KEY a7d4228d-cdb5-421a-b5cc-9f0d228a87d2
        #...    ----WebKitFormBoundary7MA4YWxkTrZu0gW
        #...    Content-Disposition    form-data; name="files"; filename="C:\TEMP\4043136189.pdf"
        #...    Content-Type    application/pdf
        #...    ----WebKitFormBoundary7MA4YWxkTrZu0gW

        &{files}=    Create Dictionary
        ...    filename    C:\\TEMP\\4043136189.pdf

        ${resp}=    POST On Session    docdigi    /api/v1/documents/annotate:financial-document    headers=&{headers}    files=&{files}
        

        #${file}=    To Json    ${resp.json()['files']['file']}
        ${respuesta}    Set Variable    ${resp.json()}
        # ${respuesta}    Convert String to Json   ${resp.json()}
        ${respuesta}    Set Variable    ${respuesta}[task]
        Log    ${respuesta}[id]
        Log    ${respuesta}[created]
        Log    ${respuesta}[status]

        #${resp}=    GET On Session    docdigi    /api/v1/tasks/

   END     

Insert Row
    ${API_URL}    Create Session Airtable
    # [Arguments]     ${row}
    
    # {
    # "records": [
    #     {
    #         "fields": {
    #             "FileName": "Factura-EASYBOTS-junio2021.pdf",
    #             "DocDigiTaskID": "75eb5373-cacd-4ed7-92be-352ed5ff3d51",
    #             "DocDigiDocumentID": "http://api.docdigitizer.com/api/v1/documents/b8e0ad38-d337-4831-acc6-3d486aa8c52f",
    #             "Estado": "Pendiente"
    #         }
    #     },
    #     {
    #         "fields": {
    #             "FileName": "Factura-EASYBOTS-junio2021.pdf",
    #             "DocDigiTaskID": "d1b602ef-0366-4347-a80f-18348a00cdd0",
    #             "DocDigiDocumentID": "http://api.docdigitizer.com/api/v1/documents/0eba1aed-b51c-4101-b125-e7a7c280d7f9",
    #             "Estado": "Pendiente"
    #         }
    #     }
    # ]
    # }

    &{invoice}=    Create Dictionary
    ...                 FileName        nombre_fichero.pdf
    ...                 DocDigiTaskID   task_id
    ...                 Estado          PENDING        

    ${json}            Convert JSON to String   ${invoice}
    ${jsonFilaAir}     Set Variable    {"records":[{"fields":${json}\}\], "typecast": true\}

    #${datos}=    Convert String to JSON     {"records":[{"fields":{"Titulo": "Prueba insercion","Fecha Limite": "2021-12-23"}}]}
    ${datos}=    Convert String to JSON     ${jsonFilaAir}
    #{"orders": [{"id": 1},{"id": 2}]}
    #${datos}    Set Variable    
    #...    "records": [
    #...    {
    #...      "fields":
    #...         {
    #...            "Titulo": "Prueba insercion",
    #...             "Fecha Limite": "2021-12-23"
    #...         }
    #...       }

    # &{data}=    Create Dictionary    latitude=30.496346    longitude=-87.640356
    #${resp}=    POST ON Session    airtable    ${INSERT_INVOICE}    json=${jsonFilaAir}
    ${resp}=    Post Request    airtable    ${API_URL}    json=${datos}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${jsondata}=    Set Variable    ${resp.json()}
    Log    ${jsondata}
