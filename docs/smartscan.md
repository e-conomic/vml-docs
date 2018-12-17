# Smartscan <small>for intelligent ERP systems</small>

## Overview
Fast and reliable request/reply API for scanning invoices and receipts.

 <!-- - [x] Doctype
 - [x] TotalInclVat -->


<!-- ## Pro tips
You can gain valuable time by grayscaling and cropping the images your sent to smartscan in advance.
This is not a neccesity, but will help and make it a better experience for the end customer. -->

## JSON API
Below you can find example calls for our JSON API. Please note we are currently running in ALPHA, so some irregularity is to be expected and response quality will improve as we work forward towards our production release.

### Python
The features list in the request data will be expanded in the future and will give more option for extending your response, an example of future functionality is to ask for an extended response containing.

#### Dependencies
Before using this code install needed dependencies using
`pip install requests click`

#### Code
Copy the code below to a file eg. scan.py and run `python scan.py local_path_to_image`

``` python tab="Python"
import base64
import json

import requests
import click


@click.command()
@click.argument('filepath')
def run(filepath):
    # Read image
    with open(filepath, 'rb') as file_:
        bytes_ = file_.read()
    # Base64 encode the image bytes
    document_b64 = base64.b64encode(bytes_)
    # Prepare request
    data = {
        "features": [{"type": "DOCUMENT_FIELD_DETECTION"}],
        "image": document_b64.decode(),
    }
    resp = requests.post(
        url='https://api.stag.ssn.e-conomic.ws/v1alpha1/scan',
        json=data,
        headers={'Authorization': 'Bearer YOUR_KEY_HERE'},
    )
    resp.raise_for_status()
    # Pretty print JSON response
    print(json.dumps(resp.json(), sort_keys=True, indent=4,
                     separators=(',', ': ')))


if __name__ == '__main__':
    run()
```

#### Response
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
