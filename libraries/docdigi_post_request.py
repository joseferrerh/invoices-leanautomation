import requests
import base64

class docdigi_post_request:

    def docdigi_upload(self):

        with open('c:\\temp\\00006.pdf', 'rb') as binary_file:
            binary_file_data = binary_file.read()
            base64_encoded_data = base64.b64encode(binary_file_data)
            base64_message = base64_encoded_data.decode('utf-8')

        # print(base64_message)


        url = "https://api.docdigitizer.com/api/v1/documents/annotate:financial-document"

        payload = "-----011000010111000001101001\r\nContent-Disposition: form-data; name=\"files\"\r\n\r\ndata:application/pdf;name=00006.pdf;base64,base64_message\r\n-----011000010111000001101001--\r\n\r\n"

        headers = {
            "Accept": "application/json",
            "Content-Type": "multipart/form-data; boundary=---011000010111000001101001",
            "Authorization": "API_KEY a7d4228d-cdb5-421a-b5cc-9f0d228a87d2"
        }

        response = requests.request("POST", url, data=payload, headers=headers)

        return(response.text)