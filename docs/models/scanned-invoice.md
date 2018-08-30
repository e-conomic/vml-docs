Scanned Invoice
===============

The Scanned Invoice model predicts and makes suggestions on texts from SmartScan - acting like a enricher, the API is located at [https://autosuggest.ml.e-conomic.ws/model/scanned-invoice/v1/predict](https://autosuggest.ml.e-conomic.ws/model/scanned-invoice/v1/predict)

The API is a train-on-call API, meaning that the model first gets trained when a request is received, this has implications on how large datasets are handled as larger datasets generally means longer training time.

Unlike other train-on-call APIs the Scanned Invoice API does not accept the actual training data in the request, but instead expects a name in the request payload, this name should then be available as a protobuf blob on S3 in a bucket called `vml-autosuggest-production` under the path `{username}/incoming/smartscan/` followed by the dataset name submitted in the payload. The `username` used, should be the username your API key corresponds to.
The recommended format for that name is the name of the integrating service, followed by a slash, and lastly the name of the dataset, such as `smartscan/10023`.

Schema
------

The service has two schemas, one for the API and one for the protobuf dataset uploaded to S3.

### API

- `text` a list of strings. Strings from the smartscan product.

### Dataset

A list of items, used to train on

- `text`, list of strings from smartscan
- `timestamp`, a datetime in the format `YYYY-MM-DDThh:mm:ssZ`
- `targets`, a map of strings and strings

Request and Response
--------------------

Example request:

```json
POST /model/scanned-invoice/v1/predict HTTP/1.1
Authorization: Bearer <secret-access-token>

{
    "dataset": "smartscan/1003372",
    "input": [
        {
            "text": [
                "1"
            ]
        }
    ],
    "options": {
        "suggestion_limit": 1
    },
    "targets": [
        "account"
    ]
}
```

And its response

```json
HTTP/1.1 200 OK
Content-Type: application/json

{
    "predictions": [
        {
            "account": [
                {
                    "confidence": 0.25,
                    "label": "1320"
                }
            ]
        }
    ]
}
```
