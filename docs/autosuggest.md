# Autosuggest <small>for intelligent ERP systems</small>

## Automate ERP Workflows
Autosuggest is a set of web APIs developed to aid automation in ERP systems.
Often customers of ERP systems are performing the same tasks many times a day,
as an example every invoice have to be booked on some account from the chart of
accounts.
Autosuggest aims to ease these manual tasks, by providing APIs that can give
suggestions to the users, so some of that work can be reduced to simply
approving what the machine learning predicted.

![asgt-explain](img/asgt-explained.png)

In the next image we see how Visma e-conomic uses the Autosuggest to fill out
accounts for a customer based on bank transfer statements.

![asgt-demo](img/asgt-demo.gif)

## Quick API Example

We have demo datasets for all our APIs, the only thing you need to get started
is to contact [Claus Dahl](mailto:claus.dahl@visma.com) for an access key.

!!! todo
    Demo datasets are not yet available

Assuming we have previously uploaded a dataset called `3124232.pb` (protobuf
format) to the scanned-invoice API, we can call the API like this:

!!! note
    Your customers behave differently and needsindividualized predictions.
    Therefore it is generally recommended to build a dataset per costumer in order
    to have the algorithms learn the correct behaviour of each customer.

```json
POST /model/scanned-invoice/v1/dataset/3124232.pb/predict HTTP/1.1
Authorization: Bearer secret-access-token

{
  "input": [
    {
      "description": "Taxi to customer meeting"
    }
  ],
  "targets": [
    "account"
  ],
  "options": {
    "suggestion_limit": 1
  }
}

HTTP/1.1 200 OK
Content-Type: application/json

{
  "predictions": [
    {
      "account": [
        {
          "confidence": 0.19,
          "label": "3620"
        }
      ]
    }
  ]
}
```

That is all. Now you can present the customer with a suggestion, booking the
invoice on account `3620` if you feel the `confidence` level is acceptable.


## Environments

The Autosuggest production environment is:

```
https://autosuggest.ml.e-conomic.ws
```

In addition we also have a staging environment available, but note that this is also the staging environment we use internally to test and roll out changes, so while it should at most times be behaving as production, at times it is unavoidable that it might be unreliable or unavailable for shorter durations. The staging environment is at:

```
https://autosuggest.staging.ml.e-conomic.ws
```

Each endpoint is mounted as a path on the host, and in the examples we have omtitted the hosts from the URL, for the sake of readability.

## Authentication

All Autosuggest endpoints require authentication in the form of a bearer header on each request. Each environment has a unique set of credentials, so if you want access to both production and staging, you will have to have two sets of credentials.

### Authenticating Requests

Say the token you have received is `348af00db8de0db6fff26b6d2c70a862`, you should include a `Authorization` header of the type `Bearer` with it in your request, here is a few snippets demonstrating how you could achieve setting the header correctly.

``` shell tab="cURL"
$ curl --header "Authorization: Bearer 348af00db8de0db6fff26b6d2c70a862" ...
```

``` python tab="Python"
import requests

resp = requests.post(
    ...
    headers={
        'Authentication': 'Bearer 348af00db8de0db6fff26b6d2c70a862',
    },
)
```

In case the API is unable to authenticate your request, you will receive a response with the status code `401` and a payload like this:

```json
HTTP/1.1 401 UNAUTHORIZED
Content-Type: application/json

{
    "name": "Unauthorized",
    "status_code": 401,
    "description": <omitted for brevity>
}
```
The `description` is a human readable text indicating what is wrong.

### Obtaining the Token

There is currently no self service way of obtaining a token for use in the autosuggest products, the only way to obtain one is to contact the Product Owner of the VML products, [Claus Dahl](mailto:claus.dahl@visma.com), and ask for one.

## Uploading Training Data

Some of the Autosuggest endpoints are designed to receive training data in the prediction request - alongside the prediction data, this approach imposes limitations on how large the dataset can be, which again limits how good the predictions can get. In addition it also impacts prediction times, as a lot of effort in the request goes into training on the dataset.

To make our predictions faster and better, we have have devised a solution that allows API integrators to submit datasets in advance, where we then have some systems working behind the scenes to train models on those datasets.

!!! note
    Not all Autosuggest endpoints currently take advantage of these mechanisms, but over time they will be migrated.

Submitting training data to autosuggest services is done by first creating a dataset and then uploading that dataset to AWS S3.
The dataset format depends on the service, as each service will make predictions on different kinds of data, but in general the datasets are packed into a binary format called ProtocolBuffers (generally referred to as protobuf).

When uploading the dataset, there is a S3 bucket defined as well as a path, the bucket is `asgt.dataset.{environment}` and the path is `{user_id}/{autosuggest_service_name}/{dataset_name}`.
Lets for the sake of an example say we are a small business accounting company called "Bills 'R Us", we have a customer called "Jimmy's Icecream Truck", and we really want to get predictions from the Autosuggest service "Electronic-Invoice-Line", in the "production" environment.

When building the dataset, it needs to be build in accordance with the format used by the model used by the Electronic-Invoice-Line service. We name the dataset something we can remember relates to the customer we want to predict on such as `jimmys-icecream-truck` (although an id of sorts would suffice as well), but it is a bit long for the example so we shorten it to `jit`. Since it is a protobuf it is required by our systems to append `.pb` to the name of the dataset, making it `jit.pb`.

!!! tip
    When training, a number of transformations happen on the data, notably the dataset gets transformed into so-called `dataframes`, where the names of the colums are derived from the names on the fields of the data. In the case the first item in the protobuf is empty, the column names gets transformed incorrectly, and as a result the dataset does not contain any targets.

    So make sure the datasets do not contain empty lines.

With the dataset in hand, we can now upload it. Since we want to upload it to the production environment, we need to upload it to the S3 bucket called `asgt.dataset.production` with the path `bru/electronic-invoice-line/jit.pb`, with `bru` being the username of our company account.
We use AWS access credentials provided by the VML product team - the developers behind the Autosuggest service.

Once we have uploaded the data the Autosuggest systems take over, training the model for the service with the dataset, producing as many targets as the datasets defines.

Training time depends on the size of the dataset, specifically the number of classes and the number of targets in the dataset. So if your dataset contains many classes and many targets, expect that training time can take a while.

### Uploading Examples

There are many ways to upload data to S3, and most languages have SDKs (if not several) for AWS services - or at very least just to S3. Below we have simple code examples of how you could upload data.

``` shell tab="Shell"
$ aws s3 cp jit.pb s3://asgt.dataset.production/bru/electronic-invoice-line/
```

``` python tab="Python"
import boto3

s3 = boto3.client('s3')

local_dataset_path = 'jit.pb'
dataset_path = 'bru/electronic-invoice-line/jit.pb'
bucket_name = 'asgt.dataset.production'

s3.upload_file(local_dataset_path, bucket_name, dataset_path)
```

!!! note
    The shell method is generally not recommended for production, but rather as a quick and easy way to get started. Although if you are missing good S3 SDKs, it could still be used as a last resort.

## Models

### Electronic Invoice Line

Othsewise known as EIL, it can make predictions on how to categorize a new invoice line, in a HTTP request, given historic categorizations, given from the training data in the dataset.

!!! warning
    Improve the description of what the EIL actually does, explain model and targets.

#### Endpoint

The Electronic Invoice Line model endpoint is

```
/model/electronic-invoice-line/v1/dataset/{dataset_name}/predict
```

Obviously the `dataset_name` would need to be replaced with whichever dataset you want your predictions to be based on. Likewise your authentication needs to have rights to access to the trained model, as explained in the [data upload section](#uploading-training-data).

Combine the endpoint the URL of the [environment](#environments) you want to use to get the full URL.

#### Schema

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

#### As Training Data

A dataset consists of multiple invoice lines all packed up into one protobuf file. The protobuf contains a top level item called `Dataset` and under that is a sequence of items called `invoicelines`, where all the invoice lines that make up a dataset goes.

!!! warning
    Include a link to the protobuf definition, that is easier to get to than the file in the github repo.

#### Example Request

When calling the service API, payload would look like this, assuming the dataset we previously uploaded is called `jit.pb`:

```json
POST /model/electronic-invoice-line/v1/dataset/jit.pb/predict HTTP/1.1
Authorization: Bearer <secret-access-token>

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

#### Caveats

- **Zero Confidence Predictions**: Some times the dataset only provide one classification for a certain value, as a safety mechanism the EIL model will in those cases return a prediction with 0 confidence, based on the assumption that the dataset was biased.

- **Not Found Responses**: As a model trains and targets are saved, they gradually become available via the API. As a result you might not see the trained targets available right away, but it should be reasonably safe to just repeat calling the prediction endpoint until the model becomes available - although the usual backoff is recommended.
Furthermore, even a single unavailable target will currently abort the request, therefore it is generally advised to call targets individually, so one missing target will not distrubt predictions on other targets.

### Bank Entries

The Bank API is a train-on-call ML API, meaning that the training dataset is provided in the request payload along with the prediction data. This imposes some limits on how large the training data can be in order to keep response times acceptable.

The API and the model it uses is made to make bank reconciliation easier by providing suggestions on how to act on the data.

#### Endpoint

The prediction endpoint is

```
/model/bank/v1/predict
```

Because the model trains on request, there is no need to specify a dataset in the path of the URL.

Combine the endpoint the URL of the [environment](#environments) you want to use to get the full URL.

#### API Schema

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
POST /model/bank/v1/predict HTTP/1.1
Authorization: Bearer <secret-access-token>

{
    "prediction_data": [
        {
            "amount": 500,
            "text": "Bank Statement Line"
        }
    ],
    "training_data": [
        {
            "accountNumber": 10,
            "amount": 500,
            "entryType": 13,
            "text": "Bank Statement Line",
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
                "accountNumber": 10,
                "entryType": 13
            },
            "probability": 1.0
        }
    ]
}
```

### Scanned Invoice

The Scanned Invoice model predicts and makes suggestions on texts from SmartScan - acting like a enricher.

#### Endpoint

The Scanned-Invoice endpoint is at:

```
/model/scanned-invoice/v1/<dataset_name>/predict
```

Combine the endpoint the URL of the [environment](#environments) you want to use to get the full URL.

The API is a train-on-call API, meaning that the model first gets trained when a request is received, this has implications on how large datasets are handled as larger datasets generally means longer training time.

Unlike the other train-on-call endpoints, the Scanned Invoice endpoint does not accept the data as a part of the request. Instead the data is expected to be in the dataset bucket on S3, as described above at [Uploading Training Data](#uploading-training-data). When submitting requests the dataset name should be in the URL - currently we allow dataset names to be a path (meaning that it can include slashes), but that is only done to ease migration, ideally a dataset name should not include any slashes.

#### Schemas

The service has two schemas, one for the API and one for the protobuf dataset uploaded to S3.

**API**

- `text` a list of strings. Strings from the smartscan product.

**Dataset**

A list of items, used to train on

- `text`, list of strings from smartscan
- `timestamp`, a datetime in the format `YYYY-MM-DD'T'hh:mm:ss'Z'`
- `targets`, a map of strings and strings

#### Example Request

Example request:

```json
POST /model/scanned-invoice/v1/predict HTTP/1.1
Authorization: Bearer <secret-access-token>

{
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

### Product Info

The Product Info API is a small ML API build for Kompa.new. The service takes
the text from an invoice/order line and maps the text to a unit and unit_type.

The use case is to automaticly fill out the unit of an orderline that has been
entered as part of creating an invoice.

The service has models for `da` and `se`.

#### Endpoint

The Product Info endpoint is:

```
/model/albert-productinfo/v1/predict
```

Combine the endpoint the URL of the [environment](#environments) you want to use to get the full URL.

#### API Schema
The API takes a JSON payload with `input` and `language` being required keys.

- `input`: a list of strings (order line entries)
- `language`: Should be set to either `da` or `se`

A full example of a API call can be seen below:

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

### Supplier Name

The supplier name model uses pretrained models of known suppliers to suggest how the supplier should be classified.

#### Endpoint

The supplier name endpoint is:

```
/model/supplier-name/v1/predict
```

Combine the endpoint the URL of the [environment](#environments) you want to use to get the full URL.

#### Schema

When making requests, all that is required is the `prediction_data` and the `options` fields.

`prediction_data` is suppose to be a list of mappings containing just one key-value pair called `supplier_name`.

`options` there is two fields:

- `suggestion_limit`: a integer limiting how many suggestions will be returned.
- `class_filter`: list of known classes to limit suggestions to, set this to `null` if you do not want the suggestions limited.

#### Example Request

```json
POST /model/supplier-name/v1/predict HTTP/1.1
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

## Troubleshooting

The Autosuggest API tries to be as helpful as possible, so even in the event that the data in the request is malformed, the schema validation will try make sure to provide some meaningfull feedback on what is wrong with the data. So if you happen to get a 400 Bad Request response, the easiest way to debug this is to inspect the JSON of the response.
