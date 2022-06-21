import base64

class base64File:

    def saveFileBase64(self, filename, base64string):

        with open(filename, "wb") as f:
            #f.write(codecs.decode(base64string, "base64"))
            f.write(base64.b64decode(base64string))


