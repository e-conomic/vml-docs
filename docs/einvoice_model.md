Electronic Invoice Line Model
=============================

<What it does...>

Schema
------

The base schema of the Electronic Invoice Line is the following fields:

- `issue_date`: The invoice timestamp, using the format `YYYY-MM-DD'T'hh:mm:ss'Z'`
- `currency`: The name of the currency as a string
- `supplier_id`: The id of the supplier, not nullable
- 'supplier_name': The name of the supplier
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

Request and Response
--------------------

When calling the service API, payload would look like this:

```json
POST /model/electronic-invoice-line/v1
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

Each prediction include the predicted value as well as the confidence the model provided as a float between 0 and 1, with 2 digits after the decimal point precision.
Having the confidence included means that you can discard predictions under a certain confidence, but the precise cut-off point is likely to depend on the needs of the individual integration case.

The response may also include other headers, but those should not be seen as a part of the API and may change over time.
