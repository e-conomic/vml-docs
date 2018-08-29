Scanned Invoice
===============

The Scanned Invoice model predicts and makes suggestions on

The API is a train-on-call API, meaning that the model first gets trained when a request is received, this has implications on how large datasets are handled as larger datasets generally means longer training time.

Unlike other train-on-call APIs the Scanned Invoice API does not accept the actual training data in the request, but instead expects a name in the request payload, this name should then be available as a protobuf blob on S3 in a bucket called `vml-autosuggest-production` under the path `incoming/smartscan/` followed by the dataset name submitted in the payload.

!!! warning
    These docs are currently incomplete


Example request:

```json
POST
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
