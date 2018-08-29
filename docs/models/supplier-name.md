Supplier Name
=============

The supplier name model uses pretrained models of known suppliers to suggest how the supplier should be classified.

Location
--------

The supplier name endpoint is located at: [https://autosuggest.ml.e-conomic.ws/model/supplier-name/v1/predict](https://autosuggest.ml.e-conomic.ws/model/supplier-name/v1/predict).

Schema
------

When making requests, all that is required is the `prediction_data` and the `options` fields.

`prediction_data` is suppose to be a list of mappings containing just one key-value pair called `supplier_name`.

`options` there is two fields:

- `suggestion_limit`: a integer limiting how many suggestions will be returned.
- `class_filter`: list of known classes to limit suggestions to, set this to `null` if you do not want the suggestions limited.

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
