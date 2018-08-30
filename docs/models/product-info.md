# Product Info

The Product Info API is a small ML API build for Kompa.new. The service takes
the text from an invoice/order line and maps the text to a unit and unit\_type.

The use case is to automaticly fill out the unit of an orderline that has been
entered as part of creating an invoice.

The service has models for `da` and `se`.

## Location
The api is available here:
```
https://autosuggest.ml.e-conomic.ws/model/albert-productinfo/v1/predict
```

## API Schema
The API takes a JSON payload with `input` and `language` being required keys.

* `input`: a list of strings (order line entries)
* `language`: Should be set to either `da` or `se`

An full example of a API call can be seen below:

```json
POST /model/bank/v1/predict HTTP/1.1
Authorization: Bearer <secret-access-token>

{
    "input": [
        "Taxa",
        "Stof",
        "Kartofler"
    ],
    "language": "dk"
}
```

The response has three suggestions for each string, sorted by confidence.
An example is shown below

```json
HTTP/1.1 200 OK
Content-Type: application/json

{
    "predictions": [
        [
            {
                "confidence": 0.947,
                "label": {
                    "unit": "stk",
                    "unit_type": "good"
                }
            },
            {
                "confidence": 0.007,
                "label": {
                    "unit": "time(r)",
                    "unit_type": "service"
                }
            },
            {
                "confidence": 0.006,
                "label": {
                    "unit": "meter",
                    "unit_type": "good"
                }
            }
        ],
        [
            {
                "confidence": 0.513,
                "label": {
                    "unit": "meter",
                    "unit_type": "good"
                }
            },
            {
                "confidence": 0.354,
                "label": {
                    "unit": "stk",
                    "unit_type": "good"
                }
            },
            {
                "confidence": 0.058,
                "label": {
                    "unit": "dag(e)",
                    "unit_type": "service"
                }
            }
        ],
        [
            {
                "confidence": 0.783,
                "label": {
                    "unit": "kg",
                    "unit_type": "good"
                }
            },
            {
                "confidence": 0.139,
                "label": {
                    "unit": "stk",
                    "unit_type": "good"
                }
            },
            {
                "confidence": 0.026,
                "label": {
                    "unit": "time(r)",
                    "unit_type": "service"
                }
            }
        ]
    ]
}
```
