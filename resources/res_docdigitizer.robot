*** Settings ***
Documentation     Keywords to deal with the AIRTABLE API
Library           RPA.HTTP
Library           RPA.JSON
Library           RPA.Robocorp.Vault

*** Keywords ***
Create Session DocDigitizer
    ${secret}        Get Secret    DocDigitizer
    &{headers}=      Create Dictionary
    ...  Accept            application/json
    ...  Authorization     API_KEY ${secret}[API_KEY]

    Create Session    docdigitizer    https://api.docdigitizer.com    headers=${headers}


*** Keywords ***
Send to DocDigitizer
    [Arguments]    ${fileName}

    #${fileContent}=  Get File For Streaming Upload  account-e1b4f5c6-ab31-4aaf-a085-ef071d7a974d-invoice-in_1KjY68BlIqXyF9j068WJMbjS.pdf
    ${fileContent}=  Get File For Streaming Upload  ${fileName}
    &{files}=  Create Dictionary  
    ...    files  ${fileContent}
    ...    callback_url     https://x62alewupbtvy25su7rqkpnbpq0fxqxy.lambda-url.eu-west-1.on.aws/

    &{data}=    Create Dictionary
    ...    files            ${files}
    ...    callback_url     https://x62alewupbtvy25su7rqkpnbpq0fxqxy.lambda-url.eu-west-1.on.aws/

    ${responseDocDigi}=  Post On Session    docdigitizer  /api/v1/documents/annotate:financial-document  files=${files}

    Log    ${responseDocDigi}
    #${responseDocDigi}    Convert String to JSON    {"detail": "Accepted", "status": 202, "task": {"created": "2022-04-08T00:14:37.641664", "id": "43917093-0633-4600-bbc7-c465d58cab4e", "status": "PENDING", "links": {"self": "/api/v1/tasks/43917093-0633-4600-bbc7-c465d58cab4e", "collection": "/api/v1/tasks"}}}
    [Return]    ${responseDocDigi.json()}




*** Keywords ***
Send to DocDigitizer Funciona Sin CallBack
    [Arguments]    ${fileName}

    #${fileContent}=  Get File For Streaming Upload  account-e1b4f5c6-ab31-4aaf-a085-ef071d7a974d-invoice-in_1KjY68BlIqXyF9j068WJMbjS.pdf
    ${fileContent}=  Get File For Streaming Upload  ${fileName}
    &{files}=  Create Dictionary  files  ${fileContent}

    ${responseDocDigi}=  Post On Session    docdigitizer  /api/v1/documents/annotate:financial-document  files=${files}

    #${responseDocDigi}    Convert String to JSON    {"detail": "Accepted", "status": 202, "task": {"created": "2022-04-08T00:14:37.641664", "id": "43917093-0633-4600-bbc7-c465d58cab4e", "status": "PENDING", "links": {"self": "/api/v1/tasks/43917093-0633-4600-bbc7-c465d58cab4e", "collection": "/api/v1/tasks"}}}
    [Return]    ${responseDocDigi.json()}

