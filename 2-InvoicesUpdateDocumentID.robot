*** Settings ***
Documentation     Lee las facturas de una carpeta o folder y las envia a docdigitizer y airtable
Library           RPA.HTTP
Library           RPA.core.notebook
Library           RPA.JSON
Library           RPA.FileSystem
Library           OperatingSystem
Library           String
Library           Collections
Library           docdigi_post_request
Resource          res_airtable.robot
Resource          res_docdigitizer.robot
#Suite Setup       Setup
#Suite Teardown    Teardown

*** Tasks ***
Invoices Update DocumentID in AirTable

    ${API_URL}    Create Session Airtable
    Create Session DocDigitizer
    
    # Query the New invoices in AirTable
    # Those invoices has been manually uploaded by the user 

    # ${resp}     Get Request     airtable    ${API_URL}?maxRecords=100&filterByFormula=documentID%3D""&sort%5B0%5D%5Bfield%5D=invoiceName
    # ${jsondata}=    To Json    ${resp.content}

    &{params}=    Create Dictionary
    ...    maxRecords=100
    ...    filterByFormula=documentID=""
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
        #[Tags]    post
        # Obtenemos el Attachment del registro de AirTable
        # y lo enviamos a docDigitizer

        Log    ${invoice}
        ${idAirTable}     Set Variable    ${invoice}[id]
        ${task_id}     Set Variable    ${invoice}[fields][taskID]
        Log    ${task_id}

        ${resp}=    GET On Session    docdigitizer    /api/v1/tasks/${task_id}

        Log    ${resp}
        Log    ${resp.json()}

        # Aqui se intentaba leer el documento pero la mayor parte de las veces NO VIENE
        # Asi qe hay que crear otro STEP que interrogue las facturas con task y sin documento y actualice Airtable
        ${respDocument}    Set Variable    ${resp.json()}[document]
        Log    ${respDocument}[id]

        ${jsonFilaAir}     Set Variable    {"records":[{\"id\": "${idAirTable}", \"fields\": {"Status": "In progress", "documentID": "${respDocument}[id]"}}\]\}
        Log     ${jsonFilaAir}

        ${datos}=    Convert String to JSON     ${jsonFilaAir}

        Log     Actualizar registro
        #${resp}=    Patch Request    Airtable    ${INVOICES_API_URL}/${idAirTable}    json=${datos}
        ${resp}=    PATCH On Session    Airtable    ${API_URL}    json=${datos}
        Should Be Equal As Strings    ${resp.status_code}    200
        ${jsondata}=    To Json    ${resp.content}


        #${invoice_data}    Set Variable    ${respDocument}[annotations][data]
        #Update Airtable Record    ${idAirTable}    ${invoice_data}

    END     
