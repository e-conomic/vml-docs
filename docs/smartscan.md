# Document annotator <small>for intelligent ERP systems</small>

## Overview
Fast and reliable request/reply API for scanning invoices and receipts.

## API
The API is documented in our protobuf files that you can find [here](https://github.com/e-conomic/vmlapis/blob/master/proto/ssn).
The top level API is [here](https://github.com/e-conomic/vmlapis/blob/master/proto/ssn/annotator/v1/annotator.proto) - but the example below should get you going.

You can find all available output fields [here](https://github.com/e-conomic/vmlapis/blob/master/proto/ssn/annotator/v1/annotator.proto#L85-L169).
Comments in the protobuf will contain information on fields that have unique traits.

The max request size is 10485760 Bytes (10Mb). Requests bigger than the max request size will result in a 413 response.

### Requesting access
To get started quickly you can use "demo" as an API token. It's heavily rate limited, but fine for development purposes. Do not use it in production!

To get real access to the API contact us on [Slack](https://visma.slack.com/messages/CG5LXV5ST) or on our [support email](mailto:vmlsupport@e-conomic.com)

### Endpoints
Annotator endpoints are located at

- Staging: `https://api.stag.ssn.visma.ai/v1/document:annotate`
- Production: `https://api.prod.ssn.visma.ai/v1/document:annotate`

Access endpoints are located at

- Staging: `https://api.stag.ssn.visma.ai/v1/access/valetkey`
- Production: `https://api.prod.ssn.visma.ai/v1/access/valetkey`

Feedback endpoints are located at

- Staging: `https://api.stag.ssn.visma.ai/v1/feedback:create` and `https://api.stag.ssn.visma.ai/v1/feedback:delete`
- Production: `https://api.prod.ssn.visma.ai/v1/feedback:create` and `https://api.prod.ssn.visma.ai/v1/feedback:delete`

### Authentication
Authentication is done using a bearer token, set it in the Authorization header as follows.

```http
Authorization: Bearer Token
```

You can use an API token for server to server communication, and you can issue a valet key for use by mobile/web clients. Please do not put your api token into an untrusted client like a mobile application!

For a mobile/web application, you have two options; either call our Access API (server side) to issue a valet key that the application can use to talk to smartscan on your behalf, or if you have an OpenID Connect based identity provider (ie. Visma Connect) you can reuse existing authentication.

Reusing existing authentication for mobile will be beneficial both for performance and you can avoid having to do backend work. The flow used on mobile is called "PKCE for OAuth2.0" ([RFC7636](https://tools.ietf.org/html/rfc7636)), and Visma Connect has nice description on [Confluence](https://confluence.visma.com/display/PROV/Visma+Connect+OAuth+2.0+Authorization+Code+Grant+with+PKCE). We support both Access Tokens and Identity Tokens, for ease of use and quick on-boarding. Please note that this technique is not limited to Visma Connect, any OAuth / OpenID Connect provider that exposes a JSON Web Key Endpoint can be used. Contact us on [slack](https://visma.slack.com/messages/CG5LXV5ST) or [email](mailto:vmlsupport@e-conomic.com) if you would like to implement this flow.

For Visma assets, we have a deep dive on client authentication on [Confluence](https://confluence.visma.com/display/VML/Solution+Design%3A+Authentication%2C+Client-side+API+Calls).

### Valet Key Request

You provide a sub(ject) and get back a token. The subject is optional, but highly recommended.

The subject will later be used for tagging any data stored by smartscan, so you can later delete said data for GDPR compliance. You will be able to add additional tags when we store the data.

You will get back an ID and a Token. The ID is not currently used, but we plan to support revoking tokens by ID.

You can set a custom expiration date by providing an unix timestamp in the field "exp", but it has to be less than 48 hours in the future. We only support short lived tokens for the valet key flow. The default expiry is 8 hours.

```json
POST /v1/access/valetkey HTTP/2
Host: api.stag.ssn.visma.ai
User-Agent: curl/7.54.0
Accept: */*
Authorization: Bearer demo
content-type: application/json

{"sub":"1234"}


HTTP/2 200
content-type: application/json
grpc-metadata-content-type: application/grpc
date: Thu, 27 Jun 2019 10:34:34 GMT
server: envoy

{"id":"50f4b3ad-865b-4be8-8462-d5e9337f2f15","token":"eyJhb...oXA"}
```


### Rate limiting
All users of the API will be limited to *300* requests per rolling minute. This is enforced on a per token level. A portion of
the 300 requests are for bursts of traffic.

Every API response will return the following rate limit headers

`x-ratelimit-limit`: The number of burst requests the current API token can perform.

`x-ratelimit-remaining`: The number of burst requests left.

`retry-after`: If you have been ratelimited based on the above headers, this indicates how many seconds until you are allowed to send traffic again. and always -1 if the action was allowed

`x-ratelimit-reset`: The number of seconds until the limit will reset to its maximum capacity

### Document data sources
The caller can choose either to send the document data as part of the request.
key field`content` is the document data base64 encoded.

NOTE: In addition to standard base64, your platform standard library probably defines a version of base64 intended
specifically for email/MIME applications - which adds line breaks every 76 characters.
Since this isn't email we don't support MIME-centric base64 - but [rfc4648](https://tools.ietf.org/html/rfc4648) base64.
For Java developers this means you should use the `Basic` encoder from `java.util.Base64` not the `MIME` encoder.
For .NET developers it means you should avoid the `InsertLineBreaks` option for `System.Convert.ToBase64String`.
For other platforms - consult the documentation.

```json
{
    "document": {
        "content": "Vl00oANHjF3gxaYT4fQ0PSDJwwZIuMLl0GdNlgyKhF4KYOtcH3r..."
    },
    "features": [{"type": "DEFAULT"}]
}
```

there is also the option to send an url to the api and the service will fetch and process the document


```json
{
    "document": {
        "source": {
            "httpUri": "https://mydata.amazonaws.com/bucket/image.png?AWSAccessKeyId=AKIAJLABBAD5ID&Signature=uC5ezkV%2B%2F76Dy0mp2vH85QojB0E%3D&Expires=1456878852"
        }
    },
    "features": [{"type": "DEFAULT"}]
}
```

### Confidence Levels
Allowed values for confidence level is
```
VERY_HIGH, HIGH, MID, LOW, VERY_LOW
```

### Features

The caller can specify which prediction operations he wants the api to perform. The full list of features are

| Feature name                         | Description                                                   |
|--------------------------------------|---------------------------------------------------------------|
|ORDER_DATE                            | Invoice Date/Document date                                    |
|PAYMENT_DUE_DATE                      | Payment date (No support for inferred dates (e.g. `8 days`)   |
|CURRENCY                              | Three letter currency code                                    |
|TOTAL_VAT                             |                                                               |
|TOTAL_INCL_VAT                        |                                                               |
|TOTAL_EXCL_VAT                        |                                                               |
|SUPPLIER_CORPORATE_ID                 | Organization number of supplier (typically the EU Vat number) |
|SUPPLIER_COUNTRY_CODE                 | Two letter country code                                       |
|DOCUMENT_TYPE                         | Answer is either `Invoice` or `receipt`                       |
|PAYMENT_METHOD                        | Cash or credit card  (heuristic)                              |
|CREDIT_CARD_LAST_FOUR                 | For receipts, the 4 last digits of card if present (heuristic)|
|INVOICE_NUMBER                        |                                                               |
|OCR_LINE_DK_TYPE                      | FIK Type field                                                |
|OCR_LINE_DK_PAYMENT_ID                | FIK Debitor or payment reference                              |
|OCR_LINE_DK_CREDITOR_ID               | FIK Account number                                            |
|OCR_LINE_SE_PAYMENT_ID                |                                                               |
|OCR_LINE_SE_BANKGIRO_CREDITOR_ID      |                                                               |
|OCR_LINE_SE_PLUSGIRO_CREDITOR_ID      |                                                               |
|OCR_LINE_NO_PAYMENT_ID                | KID number                                                    |
|OCR_LINE_FI_PAYMENT_ID                |                                                               |
|OCR_LINE_NL_PAYMENT_ID                |                                                               |
|IBAN                                  | IBAN code. (heuristic)                                        |
|TEXT                                  | The full ASCII text of the document                           |
|TEXT_ANNOTATION                       | The full OCR output for the document                          |
|LINES                                 | Line text for invoice lines (heuristic, experimental)         |
|PREVIEW                               | Base64 encoded rendering of first page of pdfs                |
|DEFAULT                               | A selection of frequently useful fields - see below           |

Heuristic indicates that the fields is returned using pattern matching, not a trained ML model.

The `DEFAULT` feature includes the following fields

```
ORDER_DATE
PAYMENT_DUE_DATE
CURRENCY
TOTAL_VAT
TOTAL_INCL_VAT
TOTAL_EXCL_VAT
SUPPLIER_CORPORATE_ID
SUPPLIER_COUNTRY_CODE
DOCUMENT_TYPE
PAYMENT_METHOD
CREDIT_CARD_LAST_FOUR
INVOICE_NUMBER
```

For each feature the caller can set `maxResults` (defaults to 1) and `minConfidence` (defaults to `HIGH`).
If both `DEFAULT` and a specific feature is set, the (settings for the) specific feature will take precedence.

See the example below.

### Example request

```json
POST /v1/document:annotate HTTP/1.1
Accept: application/json, */*
Accept-Encoding: gzip, deflate
Authorization: Bearer ***************************
Connection: keep-alive
Content-Length: 272
Content-Type: application/json
Host: api.prod.ssn.visma.ai
User-Agent: HTTPie/0.9.9

{
    "document": {
        "source": {
            "httpUri": "http://examplehost.com/testing-document.pdf"
        }
    },
    "features": [
        {"type": "DEFAULT"},
        {"type": "CURRENCY", "maxResults": 2, "minConfidence": "VERY_LOW"},
        {"type": "TEXT"}
    ]
}

HTTP/1.1 200 OK
content-type: application/json
date: Fri, 03 May 2019 08:53:53 GMT
grpc-metadata-content-type: application/grpc
retry-after: -1
server: envoy
transfer-encoding: chunked
x-envoy-upstream-service-time: 444
x-ratelimit-limit: 46
x-ratelimit-remaining: 45
x-ratelimit-reset: 0

{
    "currency": [
        {
            "confidence": {
                "level": "VERY_HIGH"
            },
            "value": "DKK"
        },
        {
            "confidence": {
                "level": "VERY_LOW"
            },
            "value": "SEK"
        }
    ],
    "documentType": [
        {
            "confidence": {
                "level": "VERY_HIGH"
            },
            "value": "Invoice"
        }
    ],
    "invoiceNumber": [
        {
            "boundingBox": {
                "normalizedVertices": [
                    {"x": 0.4180645, "y": 0.1504109},
                    {"x": 0.4633548, "y": 0.1504109},
                    {"x": 0.4633548, "y": 0.1619178 },
                    {"x": 0.4180645, "y": 0.1619178 }
                ],
                "vertices": [
                    {"x": 518, "y": 263},
                    {"x": 574, "y": 263},
                    {"x": 574, "y": 283},
                    {"x": 518, "y": 283}
                ]
            },
            "confidence": {
                "level": "VERY_HIGH"
            },
            "text": "368254",
            "value": "368254"
        }
    ],
    "supplierCorporateId": [
        {
            "boundingBox": {
                "normalizedVertices": [
                    {"x": 0.13277419, "y": 0.4471233},
                    {"x": 0.16722581, "y": 0.4471233},
                    {"x": 0.16722581, "y": 0.4534246},
                    {"x": 0.13277419, "y": 0.4534246}
                ],
                "vert`ices": [
                    {"x": 207, "y": 783},
                    {"x": 164, "y": 783},
                    {"x": 207, "y": 794},
                    {"x": 164, "y": 794}
                ]
            },
            "confidence": {
                "level": "VERY_HIGH"
            },
            "text": "70986310",
            "value": "70986310"
        }
    ],
    "supplierCountryCode": [
        {
            "confidence": {
                "level": "VERY_HIGH"
            },
            "value": "DK"
        }
    ],
    "text": "PRINTER\nPATRONER.DK\nClaus Dahl\nAbel Cathrinesgade 6 4.th.\n1654 København V\nDanmark\nAtt.: Claus Dahl\nMaigårdsvej 4\n9900 Frederikshavn\nTlf: 98 48 06 77\nFAKTURA\nFaktura\nDato ...\nSide ...........\nKonto\n101526\n13/07-16\nINTERNET\n368254\nOrdrenummer ...:\nMomsnummer ...:\nFaktura betalt med Dankort\nSælger ............: Lars Lund\nRekvisition .........\nFølg din pakke via Track & Trace ved at klikke på dette link:\nhttp://logistics.postennorden.com/wsp/widgets/ntt-widget/tt-post-DK-da.htm?id=e43d49af-0025-060b-7059-4194-a3bf-1b3aa4663508-831847036082\nVarenummer Tekst\nAntal\nenhed\nBeløb\nDKK\nPris\n1,00\nHPCN053AE Blækpatron sort No.932XL HP Original\nHPCN054AE Blækpatron cyan No.933XL HP Original\nHP CN055AE Blækpatron mag No.933XL HP Original\nHPCN056AE Blækpatron yel No.933XL HP Original\n1,00\n1,00\n1,00\n226,00\n107,00\n107,00\n107,00\n226,00\n107,00\n107,00\n107,00\nForsendelse ........:\n31,00\nTotal excl. moms\n462,40\nMoms\n25,00%\nMomsbeløb\n115,60\nTotal beløb DKK\n578,00\nE-Mail: kundeservice@printerpatroner.dk - www.printerpatroner.dk\nCVR: 70986310 - Bank: Nordjyske Bank - Konto nr.: 8090 0001066391\n",
    "totalExclVat": [
        {
            "boundingBox": {
                "normalizedVertices": [
                    {"x": 0.21870968, "y": 0.42821917},
                    {"x": 0.24154839, "y": 0.42821917},
                    {"x": 0.24154839, "y": 0.43315068},
                    {"x": 0.21870968, "y": 0.43315068}
                ],
                "vertices": [
                    {"x": 271, "y": 750},
                    {"x": 299, "y": 750},
                    {"x": 299, "y": 758},
                    {"x": 271, "y": 758}
                ]
            },
            "confidence": {
                "level": "HIGH"
            },
            "text": "462,40",
            "value": "462.40"
        }
    ],
    "totalInclVat": [
        {
            "boundingBox": {
                "normalizedVertices": [
                    {"x": 0.44090322, "y": 0.4279452},
                    {"x": 0.46219355, "y": 0.4279452},
                    {"x": 0.46219355, "y": 0.4336986},
                    {"x": 0.44090322, "y": 0.4336986}
                ],
                "vertices": [
                    {"x": 546, "y": 749},
                    {"x": 573, "y": 749},
                    {"x": 573, "y": 759},
                    {"x": 546, "y": 759}
                ]
            },
            "confidence": {
                "level": "VERY_HIGH"
            },
            "text": "578,00",
            "value": "578.00"
        }
    ],
    "totalVat": [
        {
            "boundingBox": {
                "normalizedVertices": [
                    {"x": 0.3410322, "y": 0.42849314},
                    {"x": 0.3619355, "y": 0.42849314},
                    {"x": 0.3619355, "y": 0.43342465},
                    {"x": 0.3410322, "y": 0.43342465}
                ],
                "vertices": [
                    {"x": 422, "y": 750},
                    {"x": 448, "y": 750},
                    {"x": 448, "y": 759},
                    {"x": 422, "y": 759}
                ]
            },
            "confidence": {
                "level": "HIGH"
            },
            "text": "115,60",
            "value": "115.60"
        }
    ]
}
```
### Results
Results for each field is returned sorted by their confidence level going from the most confident to the least confident.
#### Additional info on credit card last four
At the moment the credit_card_last_four feature does not have boundary boxes as we do not have data to train for this feature, predictions for this features is therefore solved in a different manner, first priority was to be able to predict the field, secondly we will find a way to add boundary boxes.


### Feedback
A feedback id is returned when annotating documents, this ID can be used to provide feedback. The feedback data will be used to generate stats regarding the results provided by smartscan and how end users interact with these results. As well as continous training of our models.

### Provide feedback
Providing feedback is available for all succesfully annotated documents, within 24 hours of the annotation, this limit may be made longer if needed. Providing feedback for a document after 24 hours will result in a 404 not found, as will feedback provided for a document that already has had feedback provided. Quickly doing multiple feedback calls for the same document might result in a 409 CONFLICT for some of the calls, and subsequently will result in 404 errors when the first call completes and temporary stored data is removed.

```json
POST /v1/feedback:create HTTP/1.1
Accept: application/json, */*
Accept-Encoding: gzip, deflate
Authorization: Bearer ***************************
Connection: keep-alive
Content-Length: 500
Content-Type: application/json
Host: api.stag.ssn.visma.ai
User-Agent: HTTPie/0.9.9

{
    "id": "65226d1b-1c70-425c-9288-a29106928ef2",
    "tags": [
        "foo",
        "bar",
        "baz",
        "qux"
    ],
    "true_values": {
        "currency": "DKK",
        "invoice_number": "1202942",
        "order_date": {
            "day": 1,
            "month": 1,
            "year": 2019
        },
        "payment_due_date": {
            "day": 1,
            "month": 1,
            "year": 2019
        },
        "total_excl_vat": 225.0,
        "total_incl_vat": 300.0,
        "total_vat": 75.0
    }
}

HTTP/1.1 200 OK
Alt-Svc: clear
Content-Length: 2
Via: 1.1 google
content-type: application/json
date: Wed, 25 Sep 2019 13:24:03 GMT
grpc-message:
grpc-status: 0
server: envoy
x-envoy-decorator-operation: dataservice.ssn.svc.cluster.local:50051/*
x-envoy-upstream-service-time: 1055

{}
```

### Data Deletion Policy and Deleting feedback
The VML team will only use the provided feedback data, to improve the system performance, as long as a consumer is using our service. If a consumer of the SmartScan API terminates their use of the service, this should be communicated to the VML team. We will then delete all feedback previously added through the API, no later than 90 days after the request. See the [Support section](http://docs.vml.visma.ai/support/) for details on how to contact. Visma Owned data is deleted three years after creation through the feedback endpoint, and all data is deleted at the end-of-life of the SmartScan service.

If an end-user of one of our consumers terminates their customer contract, it is the responsibility of the API consumer to delete this data from the SmartScan feedback store. To help ensure GDPR compliance we offer a delete endpoint with which you can delete all data related to a customer. Due to the nature of the way data is inserted in our database, we can't delete data within the first 90 minutes of insertion therefore all delete calls will be processed accordingly in a delayed job.

Deletes are done by the tags defined in your feedback call, if you define more than one tag all data that has one or more than one matching tag will be deleted.
e.g. `"tags": ["foo", "bar"]` will delete all feedback data that has either foo or bar in their tags. Ideally this will be used to batch delete calls to us, so you can call with `"tags": ["customer1", "customer2",...,"customerX"]` to delete all data related to these customers.

```json
POST /v1/feedback:delete HTTP/1.1
Accept: application/json, */*
Accept-Encoding: gzip, deflate
Authorization: Bearer ***************************
Connection: keep-alive
Content-Length: 24
Content-Type: application/json
Host: api.stag.ssn.visma.ai
User-Agent: HTTPie/0.9.9

{
    "tags": [
        "foo",
        "bar"
    ]
}

HTTP/1.1 200 OK
Alt-Svc: clear
Content-Length: 2
Via: 1.1 google
content-type: application/json
date: Wed, 25 Sep 2019 13:04:21 GMT
grpc-message:
grpc-status: 0
server: envoy
x-envoy-decorator-operation: dataservice.ssn.svc.cluster.local:50051/*
x-envoy-upstream-service-time: 5248

{}
```



### Code examples
Below will be some lightweight examples in various programming languages, that can
give you a headstart for trying out and getting a feel for the new smartscan API.
The examples can be copy pasted, and all you will have to do is replace the YOUR_TOKEN_HERE
and provide a path to a document you would like scanned.

### Supported file types
- png
- jpg
- pdf
- gif
- tif
- bmp


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
        "features": [{"type": "DEFAULT"}],
        "document": {"content": document_b64.decode()},
    }
    resp = requests.post(
        url='https://api.stag.ssn.visma.ai/v1/document:annotate',
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

```csharp
using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using Newtonsoft.Json;

namespace SmartScanTest
{
    class Program
    {
        public static void Main(string[] args)
        {
            string apiKey = "your api key";
            string urlToPdf = "url to pdf here";
            string endpointAddress = "https://api.stag.ssn.visma.ai/v1/document:annotate";

            dynamic scanRequest = new
            {
                features = new[] { new { type = "DEFAULT" } },
                document = new { source = new { httpUri = urlToPdf } }
            };

            var json = JsonConvert.SerializeObject(scanRequest);
            var requestContent = new StringContent(json, Encoding.UTF8, "application/json");

            var client = new HttpClient();
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);

            var result = client.PostAsync(new Uri(endpointAddress), requestContent);
            result.Wait();

            Console.WriteLine(result.Result);
            Console.ReadLine();
        }
    }
}

```

## REST Reference

!!swagger-http https://raw.githubusercontent.com/e-conomic/vmlapis/master/gen/openapiv2/ssn/v1.swagger.json!!
