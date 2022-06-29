*** Settings ***
Documentation     This robot reads the files in a folder and sends them to DocDigitizer to obtain the relevant data
Library           RPA.HTTP
Library           RPA.core.notebook
Library           RPA.JSON
Library           RPA.FileSystem
Library           OperatingSystem
Library           String
Library           Collections
Resource          res_airtable.robot
Resource          res_docdigitizer.robot

*** Variables ***
${INVOICES_DIR}        ${CURDIR}${/}%{INVOICES_DIR}


*** Tasks ***
Read Invoices from Folder
    Create Session Airtable
    Create Session DocDigitizer

    ${secret}        Get Secret    AirTable
    ${API_URL}=    Set Variable    ${secret}[API_URL]

    Log To Console    ${INVOICES_DIR}

    ${files}=  RPA.FileSystem.List files in directory  ${INVOICES_DIR}
    FOR    ${file}  IN  @{FILES}
        #[Tags]    post

        # The invoice is sent to DocDigitizer
        # The task_id is saved in Airtable 

        Log To Console    ${file}

        # ${resp}    Send to DocDigitizer    ${file}
        # Esto es solo para probar sin enviar a DocDigitizer
        # Respuesta ficticia para probar el flujo completo
        ${resp}    Convert String to JSON    {"detail": "Accepted", "status": 202, "task": {"created": "2022-04-08T00:14:37.641664", "id": "43917093-0633-4600-bbc7-c465d58cab4e", "status": "PENDING", "links": {"self": "/api/v1/tasks/43917093-0633-4600-bbc7-c465d58cab4e", "collection": "/api/v1/tasks"}}}
 
        Log    ${resp}
        #${respuesta}    Set Variable    ${resp.json()}
        ${task}    Set Variable    ${resp}[task]
        Log    ${task}[id]
        Log    ${task}[created]
        Log    ${task}[status]
    
        Sleep    10

        # It is not required to wait 10 secs and then retrieve the task details.
        # A schedule bot will do this job
#        ${resp}=    GET On Session    docdigitizer    /api/v1/tasks/${task}[id]

#        Log    ${resp}
#        Log    ${resp.json()}
#        ${respDocument}    Set Variable    ${resp.json()}[document]
#        Log    ${respDocument}[id]
#        Log    ${respDocument}[annotations][data]

        ${resp}    Insert into Airtable    ${API_URL}    ${file}[1]    ${task}[id]    ${EMPTY}    ${EMPTY}
        #${jsondata}=    Set Variable    ${resp.json()}
        Log    ${resp}

    END     

