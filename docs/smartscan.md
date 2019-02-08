# Smartscan <small>for intelligent ERP systems</small>

## Overview
Fast and reliable request/reply API for scanning invoices and receipts.

## JSON API
The new smartscan REST API,  to use the API you will need a token, you can request a token to the API by contacting us on our [support email](mailto:vmlsupport@e-conomic.com).

All of our APIs are documented in protobuf files that you can find [here](https://github.com/e-conomic/vmlapis/tree/master/ssn).
The top level API is [here](https://github.com/e-conomic/vmlapis/blob/master/ssn/scanner/v1/scanner.proto) - but the example below should get you going.
At the moment two types of output are available - the documentFieldDetection - which you're probably mostly interested in, but also rawTextDetection,
which is essential input if you're integrating SmartScan with AutoSuggest account predictions.

You can find all available output fields [here](https://github.com/e-conomic/vmlapis/blob/master/ssn/mlservice/v1/mlservice.proto).
Comments in the protobuf will contain information on fields that have unique traits.

When using the API please note that, an image is a file of type `jpg`, `png` or `pdf`. Multi page PDFs are treated as a single image.

```json
POST /v1/scan HTTP/1.1
Authorization: Bearer secret-access-token

{
  "features": [
      {
        "type": "DOCUMENT_FIELD_DETECTION"
      }
  ],
  "image": "/9j/2wBDAAMCAgICAgMCAgIDAwMDBAYEBAQEBAgGBgUGCQgKCgkICQkKDA8MCgsOCw"
}

HTTP/1.1 200 OK
Content-Type: application/json

{
  "documentFieldDetection": {
    "currency": {
      "confidence": 0.99999547,
      "value": "SEK"
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
    "paymentDueDate": {
      "confidence": 0.63128847,
      "value": "2017-04-01"
    },
    "supplierCorporateId": [
      {
        "confidence": 0.96503794,
        "value": "1234567"
      },
      {
        "confidence": 0.91503794,
        "value": "7654321"
      },
    ],
    "supplierCountryCode": {
      "confidence": 0.99994624,
      "value": "SE"
    },
    "totalInclVat": {
      "confidence": 0.99762625,
      "value": "163.06"
    },
    "totalVat": {
      "confidence": 0.5977386,
      "value": "31.56"
    },
    "totalExclVat": {
      "confidence": 0.5977386,
      "value": "111.5"
    },
    "ocrLineFi": {
      "paymentId": {
        "confidence": 0.55,
        "value": "117030351"
      },
      "bankgiroCreditorId": {
        "confidence": 0.87,
        "value": "52113222"
      },
      "plusgiroCreditorId": {
        "confidence": 0.87,
        "value": "3874807"
      }
    }
  }
}
```

### Supported file types
- png
- jpg
- pdf

### Endpoints
Our endpoints for Smartscan will be

- Staging: https://api.stag.ssn.e-conomic.ws/v1
- Production: https://api.prod.ssn.e-conomic.ws/v1

Where ssn is short for Smartscan.

### Code examples
Below will be some lightweight examples in various programming languages, that can
give you a headstart for trying out and getting a feel for the new smartscan API.
The examples can be copy pasted, and all you will have to do is replace the YOUR_TOKEN_HERE
and provide a path to a document you would like scanned.

#### Python

##### Dependencies
Before using this code install needed dependencies using
`pip install requests click`

##### Code
Copy the code below to a file eg. scan.py and run `python scan.py local_path_to_image`

``` python
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
        url='https://api.stag.ssn.e-conomic.ws/v1/scan',
        json=data,
        headers={'Authorization': 'Bearer YOUR_TOKEN_HERE'},
    )
    resp.raise_for_status()
    # Pretty print JSON response
    print(json.dumps(resp.json(), sort_keys=True, indent=4,
                     separators=(',', ': ')))


if __name__ == '__main__':
    run()
```

#### "C\#"

##### Dependencies
Before using this code example  you will ned to install the NuGet packages:
- RestSharp
- Newtonsoft.Json

##### Code

```csharp
// Base64 encode image
byte[] imageArray = System.IO.File.ReadAllBytes(@"PATH_TO_IMAGE_HERE");
string base64ImageRepresentation = Convert.ToBase64String(imageArray);

//Create a client and request for calling the API.
var client = new RestSharp.RestClient("https://api.stag.ssn.e-conomic.ws/v1");
var request = new RestSharp.RestRequest("scan", RestSharp.Method.POST);

//Add your token
request.AddParameter("Authorization", string.Format("Bearer " + "YOUR_TOKEN_HERE"),
RestSharp.ParameterType.HttpHeader);
request.AddJsonBody(new
{
    features = new[] { new { type = "DOCUMENT_FIELD_DETECTION"}},
    image = base64ImageRepresentation
});
var response = client.Execute(request);

// On 200 OK, parse the response content.
if ((int)response.StatusCode == 200)
{
    var res = Newtonsoft.Json.Linq.JObject.Parse(response.Content);
    Console.WriteLine(res);
}
else if (response.ResponseStatus == RestSharp.ResponseStatus.Completed)
{
    Console.WriteLine(response.Content);
}
else
{
    Console.WriteLine(response.ErrorMessage);
}
```


#### PHP

##### Code
```PHP
<?php
// Define recipients
$im = file_get_contents('PATH_TO_IMAGE_HERE');
$imdata = base64_encode($im);
$features = ["DOCUMENT_FIELD_DETECTION"];
$url = "https://api.stag.ssn.e-conomic.ws/v1/scan";
$json = [
    'features' => [],
    'image' => $imdata
];
foreach ($features as $feature) {
    $json['features'][] = ['type' => $feature];}

$ch = curl_init();
curl_setopt($ch,CURLOPT_URL, $url);
curl_setopt($ch,CURLOPT_HTTPHEADER, array("Authorization: Bearer YOUR_TOKEN_HERE"));
curl_setopt($ch,CURLOPT_POSTFIELDS, json_encode($json));
curl_setopt($ch,CURLOPT_RETURNTRANSFER, true);
$result = curl_exec($ch);
curl_close($ch);
$json = json_decode($result);
print_r($json);
```
