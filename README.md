# Robocorp project to deal with invoices, send them to docDigitizer, obtain the data from their webserice and save it into an AirTable repository

This project provides support for docDigitizer webService, in order to:

  - receive/deal with invoices in pdf or any other format
  - send them to docDigitizer and obtain a taskID
  - query docDigitizer to obtain the documentID related to the taskID
  - query again docDigitizer to obtain the document Details

Invoices are also saved and registered into an AirTable repository.

## Requirements

To operate and work with AirTable an API_KEY is required. It must be included into the Control Room:

  - A secret must exist called AirTable and must include API_KEY and API_URL
  - The API_KEY is provided by AirTable, in the API documentation. No need to include the word Bearer with the API_KEY
  - The API_URL can be obtained after registering into AirTable and replicating the following repository
      [URL-to-Replicate](https://airtable.com/shr0TBDM6vP64E81B/tbl9dHJQVF4jV90QY) 
  - After replicating the Invoice environment a URL will be provided by AirTable and must be included in the secret
      The following is an example URL in our secret: /appAbC123xYz987AZ/Invoices

To operate and work with docDigitizer an API_KEY is also required. It must be included into de control room:

  - A secret called DocDigitizer must exists and with the key API_KEY

## Tasks

> The following tasks are included as different ways to feed the invoices into the system. The most common ways to incorporate invoices into the system are:

  - Obtaining them from an emailbox.
  - Reading them from a folder

There are two robots that implement these use-cases:

  - Invoices From Folder
  - Invoices From Mailbox
  
### Invoices From Folder

This robot reads the file in a folder and send them to DocDigitizer to obtain the relevant data 

Configuration required:
  - "INVOICES_DIR": "Invoices"
  - This variable %{INVOICES_DIR} must be configured in the Robocorp Cloud for this step 

### Invoices From Mailbox

This is a very simple robot that access a mailbox, reads the emails with subject including the word "Invoice" and downloads the attachments to the previous forlder. 

Configuration required. The following variables must be configured in the Robocorp Cloud for this step :
  - "MAILSERVER": "imap.server.com"
  - "MAILPORT": "xyz",
  - "MAILBOX": "mail@domain.com"
  - "INVOICES_DIR": "Invoices"

> An additional task is included for those cases in which the invoices have been included into AirTable with STATUS=New and with the Invoices Files included as attachments.

### Invoices From AirTable

This task is used if you allow the user to upload the invoices directly to AirTable. Those invoices must be sent to DocDigitizer

They are retrieved from AirTable, the pdf file is donwloaded and a request with that invoice file is send to DocDigitizer

## Scheduled Tasks

Once the invoices has been sent to docDigitizer, two tasks are executed under an schedule:

  - Invoices Update DocumentID in AirTable
  - Invoices Update Document Details in AirTable


## API access to ROBOTS

Two tasks are provided to be used as an API

### Send Invoice to docDigitizer

  - Send Invoice to docDigitizer

  The payload to make use of this webservice is the following one:

    "payload": {
        "invoiceName": "invoice_filename.pdf",
        "invoiceId": "idCreatio-xxxx-yyyy",
        "urlCreatio": "https://host:port/path",
	  	  "invoiceContent": base64content
    }


### Get invoice Details

  - Get Details from docDigitizer Invoice

    "payload": {
        "documentID": "xxxxxxxx-yyyy-zzzz-aaaa-kkkkkkkkkkkk"
    }