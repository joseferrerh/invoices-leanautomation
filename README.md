# Robocorp project to ingest invoices, send them to docDigitizer, obtain the data from their webservice and save it to an Airtable repository

This project provides support for docDigitizer webService, in order to:

  - Receive / ingest invoices in PDF or any other format
  - Send them to DocDigitizer and obtain a taskID
  - Query DocDigitizer to obtain the documentID related to the taskID
  - Query DocDigitizer again to obtain the document Details

Invoices are also saved and registered into an Airtable repository.

## Requirements

An API_KEY is required to work with Airtable and must be included in Control Room:

  - A vault secret must exist called AirTable and must include API_KEY and API_URL
  - The API_KEY is provided by Airtable, in the API documentation. There is no need to include the word Bearer with the API_KEY
  - The API_URL can be obtained after registering into AirTable and replicating the [URL-to-Replicate](https://airtable.com/shr0TBDM6vP64E81B/tbl9dHJQVF4jV90QY) repository
  - After replicating the Invoice environment, Airtable will provide a URL that must be included in the secret. The following is an example URL in our secret: /appAbC123xYz987AZ/Invoices

To operate and work with docDigitizer, an API_KEY is also required and must be included in the Control Room:

  - A secret called DocDigitizer must exists and with the key API_KEY

## Tasks

> The following tasks are different ways to feed invoices into the system. The most common ways to incorporate invoices into the system are:

  - Reading them from a folder
  - Obtaining them from an email box.

There are two robots that implement these use-cases:

  - Invoices From Folder
  - Invoices From Mailbox
  
### Invoices From Folder

This robot reads the file in a folder and send them to DocDigitizer to obtain the relevant data 

Configuration required:
  - "INVOICES_DIR": "Invoices"
  - This variable %{INVOICES_DIR} must be configured in Robocorp Cloud for this step 

### Invoices From Mailbox

This robot accesses a mailbox, reads emails with a subject including the word "Invoice", and then downloads the attachments to the previous folder. 

Configuration required. The following variables must be configured in the Robocorp Cloud for this step :
  - "MAILSERVER": "imap.server.com"
  - "MAILPORT": "xyz",
  - "MAILBOX": "mail@domain.com"
  - "INVOICES_DIR": "Invoices"

### Invoices From AirTable

Use this task if your users upload invoices directly to Airtable. Those invoices are retrieved from Airtable, the PDF file is downloaded, and a request with that invoice file is then sent to DocDigitizer.

## Scheduled Tasks

Once invoices are sent to DocDigitizer, two tasks are executed under an schedule:

  - Invoices Update DocumentID in AirTable
  - Invoices Update Document Details in AirTable


## API access to ROBOTS

Two tasks are provided to be used as an API

### Send Invoice to docDigitizer

  - Send Invoice to docDigitizer

  The payload to make use of this web service is as follows:

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