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
Invoices Update Document Details in AirTable

    ${API_URL}    Create Session Airtable
    Create Session DocDigitizer
    
    # Query the "In progress" invoices in AirTable
    # Those invoices has been previously sent to DocDigitizer 
    #${resp}     Get Request     airtable    ${INVOICES_API_URL}?maxRecords=100&filterByFormula=Status%3D"In progress"&sort%5B0%5D%5Bfield%5D=invoiceName

    &{params}=    Create Dictionary
    ...    maxRecords=100
    ...    filterByFormula=Status="In progress"
    ${resp}     GET On Session     airtable    url=${API_URL}    params=${params}
    ${jsondata}=    set Variable    ${resp.json()}
    
    
    ${jsondata}=    To Json    ${resp.content}

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

        # No hace falta actualizar el estado puesto que el Update Airtable Record lo deja a Done
        # ${jsonFilaAir}     Set Variable    {"records":[{\"id\": "${idAirTable}", \"fields\": {"Status": "In progress", "documentID": "${respDocument}[id]"}}\]\}
        # Log     ${jsonFilaAir}

        # ${datos}=    Convert String to JSON     ${jsonFilaAir}

        # Log     Actualizar registro
        #${resp}=    Patch Request    Airtable    ${INVOICES_API_URL}/${idAirTable}    json=${datos}
        # ${resp}=    PATCH On Session    Airtable    ${INVOICES_API_URL}    json=${datos}
        # Should Be Equal As Strings    ${resp.status_code}    200
        # ${jsondata}=    To Json    ${resp.content}

        IF    ${respDocument}[reviewed]
            ${invoice_data}    Set Variable    ${respDocument}[annotations][data]
            Update Airtable Record    ${idAirTable}    ${invoice_data}
        END

    END     
