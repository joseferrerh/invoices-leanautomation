*** Settings ***
Documentation     This robot accesses a mailbox, reads emails with a subject including the word "Invoice", and then downloads the attachments to the previous folder.
Library           RPA.Email.ImapSmtp
Library           RPA.FileSystem
Library           String
Library           RPA.Robocorp.Vault

*** Variables ***
${INVOICES_DIR}        ${CURDIR}${/}%{INVOICES_DIR}
${mailbox}             %{MAILBOX}
${mailserver}          %{MAILSERVER}
${mailport}            %{MAILPORT}


*** Tasks ***
Read Invoices from Email
    Access Mailbox
    Search Emails and Download Invoices


*** Keywords ***  
Access Mailbox
    ${secret}            Get Secret    Mailbox
    ${emailpassword}=    Set Variable    ${secret}[password]

    Authorize Imap      ${mailbox}  ${emailpassword}  ${mailserver}   ${mailport}


Search Emails and Download Invoices
    @{messages}=    List Messages    criterion=SUBJECT "Invoice" UNSEEN
   
    # Loop Messahes including subject with "Invoice"
    FOR  ${message}  IN  @{messages}
        Log  ${message}[uid] ${message}[Date] ${message}[From]

        IF    ${message}[Has-Attachments]
            Log To Console    Saving attachment for: ${message}[Subject]
            ${attachments}=    Save Attachment
            ...    ${message}
            ...    target_folder=${INVOICES_DIR}
            ...    overwrite=True
            Log To Console    Saved attachments: ${attachments}
        END

        Mark As Read    UID ${message}[uid]

    END