Supplier Name
=============

The supplier name model uses pretrained models of known suppliers to suggest how the supplier should be classified.

Location
--------

The supplier name endpoint is located at: [https://autosuggest.ml.e-conomic.ws/model/supplier-name/v1/predict](https://autosuggest.ml.e-conomic.ws/model/supplier-name/v1/predict).

Schema
------

On request, just supplier names are required. They are given as a list of mappings with the key `supplier_name`.

Request and Response
--------------------

```json
POST /model/supplier-name/v1/predict
Authorization: Bearer <secret-access-token>

{
    "prediction_data": [
        {
            "supplier_name": "Dogwood Inc"
        }
    ],
    "options": {
        "suggestion_limit": 2,
        "class_filter": null
    }
}
```

```json
HTTP/1.1 200 OK
Content-Type: application/json

{
    "result": [
        {
            "known_supplier": false,
            "suggestions": [
                {
                    "class": "4000",
                    "proba": 0.09
                },
                {
                    "class": "6850",
                    "proba": 0.07
                }
            ]
        }
    ]
}
```
