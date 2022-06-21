*** Settings ***
Documentation     Keywords to deal with the AIRTABLE API
Library           RPA.HTTP
Library           RPA.JSON


*** Variables ***
${CREATIO_API_BASE_URL}=    https://118762-crm-bundle.creatio.com/0/ServiceModel/RPARobocorpInvoice.svc
${CREATIOINV_API_URL}       /InvoiceResponse

*** Keywords ***
Create Session Creatio
    #&{headers}=    Create Dictionary    Authorization=Bearer keySSjoVV4iU74779
    Create Session    creatio    ${CREATIO_API_BASE_URL}    verify=True

