Electronic Invoice Line Model
=============================

Othsewise known as EIL, it can make predictions on how to categorize a new invoice line, in a HTTP request, given historic categorizations, given from the training data in the dataset.

!!! warning
    Improve the description of what the EIL actually does, explain model and targets.

Schema
------

The base schema of the Electronic Invoice Line is the following fields:

- `issue_date`: The invoice timestamp, using the format `YYYY-MM-DD'T'hh:mm:ss'Z'`
- `currency`: The name of the currency as a string
- `supplier_id`: The id of the supplier, not nullable
- `supplier_name`: The name of the supplier
- `supplier_global_id`: The global id of the supplier
- `customer_ref`: The reference of the customer
- `total`: The total of the invoice, either a `float` or an `integer`
- `line_text`: The text of the invoice line
- `line_id`: The id of the line

As json, this could look like:

```json
{
    "issue_date": "2018-07-18T12:32:55Z",
    "currency": "DKK",
    "supplier_id": "9a3f13db-12f8-4d89-ba94-c34d89906324",
    "supplier_name": "Jimmys Icecream Truck",
    "supplier_global_id": "265193dd-627b-4896-aee4-82f376da6a84",
    "customer_ref": "2eb0e66d-8d93-405b-a90d-97ff70cb9006",
    "total": 10,
    "line_text": "icecream cone",
    "line_id": "0b678d5c-5d76-4e81-adc5-758963c52388"
}
```

Note that all fields are required, but all are nullable with the exception of `supplier_id`. So while required, sending `null` values are allowed.

As Training Data
----------------

A dataset consists of multiple invoice lines all packed up into one protobuf file. The protobuf contains a top level item called `Dataset` and under that is a sequence of items called `invoicelines`, where all the invoice lines that make up a dataset goes.

!!! warning
    Include a link to the protobuf definition, that is easier to get to than the file in the github repo.

Request and Response
--------------------

When calling the service API, payload would look like this:

```json
POST /model/electronic-invoice-line/v1/dataset/jimmys-icecream-truck.pb/predict
Authorization: Bearer secret-access-token

{
    "inputs": [
        {
            "issue_date": "2018-07-18T12:32:55Z",
            "currency": "DKK",
            "supplier_id": "9a3f13db-12f8-4d89-ba94-c34d89906324",
            "supplier_name": "Jimmys Icecream Truck",
            "supplier_global_id": "265193dd-627b-4896-aee4-82f376da6a84",
            "customer_ref": "2eb0e66d-8d93-405b-a90d-97ff70cb9006",
            "total": 10,
            "line_text": "icecream cone",
            "line_id": "0b678d5c-5d76-4e81-adc5-758963c52388"
        }
    ],
    "targets": ["target0", "target6"],
    "options": {
        "suggestion_limit": 1
    }
}
```

And the response would look like this.

```json
HTTP/1.1 200 OK
Content-Type: application/json

{
    "predictions": [
        {
            "target0": [
                {
                    "confidence": 0.51,
                    "label": "501090"
                }
            ],
            "target6": [
                {
                    "confidence": 0.26,
                    "label": "2050001112"
                }
            ]
        }
    ]
}
```

Each prediction include the predicted value as well as the confidence the model provided as a float between 0 and 1, rounded to 2 significant decimal places.
Having the confidence included means that you can discard predictions under a certain confidence, but the precise cut-off point is likely to depend on the needs of the individual integration case - in principle it could be used in the UI to indicate how much care and attention the enduser should give to ensure the data is correct.

The response may also include other headers, but those should not be seen as a part of the API and may change over time.

Caveats & Troubleshooting
-------------------------

- **Zero Confidence Predictions**: Some times the dataset only provide one classification for a certain value, as a safety mechanism the EIL model will in those cases return a prediction with 0 confidence, based on the assumption that the dataset was biased.

- **Bad Request Responses**: If you make a request to the API and get a 400 Bad Request, you are always returned a snippet of JSON, that contains information on what was wrong with the request.

- **Not Found Responses**: As a model trains and targets are saved, they gradually become available via the API. As a result you might not see the trained targets available right away, but it should be reasonably safe to just repeat calling the prediction endpoint until the model becomes available - although the usual backoff is recommended.
Furthermore, even a single unavailable target will currently abort the request, therefore it is geneally advised to call targets individually, so one missing target will not distrubt predictions on other targets.
