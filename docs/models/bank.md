Bank
====

The Bank API is a train-on-call ML API, meaning that the training dataset is provided in the request payload along with the prediction data. This imposes some limits on how large the training data can be in order to keep response times acceptable.

The API and the model it uses is made to make bank reconciliation easier by providing suggestions on how to act on the data.

Location
--------

The prediction endpoint is located at [https://autosuggest.ml.e-conomic.ws/model/bank/v1/predict](https://autosuggest.ml.e-conomic.ws/model/bank/v1/predict).

!!! warning
    These docs are currently incomplete

API Schema
----------

The API takes a JSON payload with two required lists: `prediction_data` and `training_data`. The former is filled with incomplete data to make predictions on and the latter is filled with complete entries to guide the predictions.

The base schema is as such:

- `accountNumber`: a integer
- `amount`: a number
- `entryType`: a integer
- `text`: a string
- `timestamp`: a integer, representing a UNIX timestamp

In the `prediction_data` list, the fields `amount` and `text` is required and all fields are required in the `training_data`.

An full example of a API call can be seen below:

```json
POST /model/bank/v1/predict
Authorization: Bearer secret-access-token

{
    "prediction_data": [
        {
            "amount": 1,
            "text": "ohnoes!"
        }
    ],
    "training_data": [
        {
            "accountNumber": 1,
            "amount": 1,
            "entryType": 1,
            "text": "some text",
            "timestamp": 2
        }
    ]
}
```

Would return:

```json
HTTP/1.1 200 OK
Content-Type: application/json

{
    "predictions": [
        {
            "label": {
                "accountNumber": 1,
                "entryType": 1
            },
            "probability": 1.0
        }
    ]
}
```
