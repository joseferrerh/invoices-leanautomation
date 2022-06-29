*** Settings ***
Documentation     Keywords to deal with the AIRTABLE API
Library           RPA.HTTP
Library           RPA.JSON
Library           RPA.Robocorp.Vault


*** Variables ***
${AIRTABLE_API_BASE_URL}=    https://api.airtable.com/v0


*** Keywords ***
Create Session Airtable
    ${secret}        Get Secret    AirTable
    &{headers}=    Create Dictionary    Authorization=Bearer ${secret}[API_KEY]
    Create Session    airtable    ${AIRTABLE_API_BASE_URL}    verify=True  headers=&{headers}

    ${API_URL}=    Set Variable    ${secret}[API_URL]
    [Return]    ${API_URL}

*** Keywords ***
Update Airtable Record
    [Arguments]    ${recordID}    ${invoiceData}

    ${secret}        Get Secret    AirTable
    ${API_URL}=    Set Variable    ${secret}[API_URL]
    Log    ${invoiceData}

    &{invoiceData}=       Create Dictionary
    ...           Status                   Done
    ...           document_type            ${invoiceData}[document:financial-document:document_type]
    ...           document_identifier      ${invoiceData}[document:financial-document:document_identifier]
    ...           issueDate                ${invoiceData}[document:financial-document:issue_date]
    ...           dueDate                  ${invoiceData}[document:financial-document:due_date]
    ...           supplierName             ${invoiceData}[document:financial-document:supplier_name]
    ...           currency                 ${invoiceData}[document:financial-document:currency]
    ...           amountRounding           ${invoiceData}[document:financial-document:amount_rounding]
    ...           amountTotal              ${invoiceData}[document:financial-document:amount_total]
    ...           amountBaseTotal          ${invoiceData}[document:financial-document:amout_base_total]
    ...           amountDue                ${invoiceData}[document:financial-document:amount_due]
    ...           recipientName            ${invoiceData}[document:financial-document:recipient_name]
    ...           amountTaxTotal           ${invoiceData}[document:financial-document:amount_tax_total]
    ...           supplierTaxNumber        ${invoiceData}[document:financial-document:supplier_tax_number]

    ${jsonInvoiceData}            Convert JSON to String   ${invoiceData}
            
    # Pruebas realizadas un dia horrible que no funcionaba nada
    #${jsonFilaAir}     Set Variable    {"records":[{"id": "${all_ids[${i}]}", "fields":${json}, "typecast": true\}\]\}
    #${jsonFilaAir}     Set Variable    {"records":[{"fields":{"PlazoSolicitud": "\u00daltima convocatoria, hasta el 31 de diciembre de 2020. En espera de pr\u00f3xima convocatoria"}, "typecast": true\}\]\}
    #${jsonFilaAir}     Set Variable    {"fields":{"PlazoSolicitud": "\u00daltima convocatoria, hasta el 31 de diciembre de 2020. En espera de pr\u00f3xima convocatoria"}, "typecast": true\}

    ${jsonFilaAir}     Set Variable    {"fields":${jsonInvoiceData}, "typecast": true\}
    Log     ${jsonFilaAir}

    ${datos}=    Convert String to JSON     ${jsonFilaAir}

    # ${first_record_id}    Set Variable    recrzoY0eBdgmqUIP
    Log     Actualizar registro
    #${resp}=    Patch Request    airtable    ${API_URL}/${recordID}    json=${datos}
    ${resp}=    PATCH On Session    airtable    ${API_URL}/${recordID}    json=${datos}
    Should Be Equal As Strings    ${resp.status_code}    200
    # ${jsondata}=    To Json    ${resp.content}


Insert into Airtable
    #[Arguments]    ${fileName}    ${taskID}    ${documentID}    ${invoiceId}    ${urlCreatio}
    [Arguments]    ${API_URL}    ${fileName}    ${taskID}      ${invoiceId}    ${urlCreatio}

    # Se ha eliminado el Document ID porque no siempre esta disponible
    
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

    Log    ${fileName}

    ${invoice}=    Create Dictionary
    ...                 invoiceName         ${fileName}
    ...                 taskID              ${taskID}    
    #...                 documentID          ${documentID}
    ...                 documentID          ${EMPTY}
    ...                 invoiceId           ${invoiceId}
    ...                 urlCreatio          ${urlCreatio}
    ...                 Status              New       

    ${json}            Convert JSON to String   ${invoice}
    ${jsonFilaAir}     Set Variable    {"records":[{"fields":${json}\}\], "typecast": true\}
#    ${jsonFilaAir}     Set Variable    {"records":[{"fields":${invoice}\}\], "typecast": true\}

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
    ${resp}=    POST ON Session    airtable    ${API_URL}    json=${datos}
    Log    ${resp}
    Log    ${resp.json()}
    
    #${resp}=    Post Request    airtable    ${INSERT_INVOICE}    json=${datos}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${jsondata}=    Set Variable    ${resp.json()}
    Log    ${jsondata}    

    [Return]    ${jsondata}
