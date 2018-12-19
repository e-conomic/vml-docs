# Smartscan <small>for intelligent ERP systems</small>

## Overview
Fast and reliable request/reply API for scanning invoices and receipts.

 <!-- - [x] Doctype
 - [x] TotalInclVat -->


<!-- ## Pro tips
You can gain valuable time by grayscaling and cropping the images your sent to smartscan in advance.
This is not a neccesity, but will help and make it a better experience for the end customer. -->

## JSON API
Below you can find example calls for our JSON API. Please note we are currently running in ALPHA, so some irregularity is to be expected and response quality will improve as we work forward towards our production release. The features list in the request data will be expanded in the future and will give you options for what information you would like to have returned as part of your response.

```json
POST /v1alpha1/scan HTTP/1.1
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
        url='https://api.stag.ssn.e-conomic.ws/v1alpha1/scan',
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
- RestShard
- Newtonsoft.Json

##### Code
Copy the code below and replace

```csharp
// Base64 encode image
byte[] imageArray = System.IO.File.ReadAllBytes(@"PATH_TO_IMAGE_HERE");
string base64ImageRepresentation = Convert.ToBase64String(imageArray);

//Create a client and request for calling the API.
var client = new RestSharp.RestClient("https://api.stag.ssn.e-conomic.ws/v1alpha1");
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
$url = "https://api.stag.ssn.e-conomic.ws/v1alpha1/scan";
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
