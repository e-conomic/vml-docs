# Smartscan <small>for intelligent ERP systems</small>

## Overview
Fast and reliable request reply API for scanning invoices and receipts. The apis will work as request / reply, for ease of integration.

 <!-- - [x] Doctype
 - [x] TotalInclVat -->


<!-- ## Pro tips
You can gain valuable time by grayscaling and cropping the images your sent to smartscan in advance.
This is not a neccesity, but will help and make it a better experience for the end customer. -->

## Http 1
Example scan calls. Please note we are currently running in ALPHA, so some irregularity is to be expected and responses are to be taken with a grain of salt.
Below we will provide some simple examples you can use
### Python example
The features list in the request data will be expanded in the future and will give more option for extending your response, an example of future functionality is to ask for an extended response containing.


``` python tab="Python"
import base64

import requests


def uploadv4(filename):
    with open(filename, 'rb') as f:
         b_document = f.read()
    document_b64 = base64.b64encode(b_document)
    data = {
        "features": [{"type": "DOCUMENT_FIELD_DETECTION"}],
        "image": document_b64
    }
    upload_resp = requests.post(
        url=api.stag.ssn.e-conomic.ws,
        json=data,
        headers={'Authorization': 'Bearer YOUR_KEY'},
    )
    upload_resp.raise_for_status()
    return upload_resp.json(), upload_resp.headers
```

You will receive a JSON response containing all predicted fields including a value and a confidence for the field.
```json
{
  "documentFieldDetection": {
    "currency": {
      "confidence": 0.99999547,
      "value": "EUR"
    },
    "documentType": {
      "confidence": 0.9999604,
      "value": "Invoice"
    },
    "invoiceNumber": {
      "confidence": 0.55902606,
      "value": "11703035"
    },
    "orderDate": {
      "confidence": 0.63128847,
      "value": "2017-03-17"
    },
    "supplierCorporateId": [
      {
        "confidence": 0.96503794,
        "value": "1234567"
      }
    ],
    "supplierCountryCode": {
      "confidence": 0.99994624,
      "value": "FI"
    },
    "totalInclVat": {
      "confidence": 0.99762625,
      "value": "163.06"
    },
    "totalVat": {
      "confidence": 0.5977386,
      "value": "31.56"
    }
  }
}
```
