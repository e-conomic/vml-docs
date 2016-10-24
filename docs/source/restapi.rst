.. _restapi-label:

REST Interface
==============
This documentation is still considered work in progress. But outlines how the
autosuggest api is used at this point in time.

Getting Predictions
-------------------

.. http:post:: /v1/project/:project/model/:model/predict
   :synopsis: Getting predictions from models

   Get a prediction for :code:`:project` using :code:`:model`. Authorization
   with JWT token is required. If a `dsl` claim is present in the content of
   the JWT token the `dsl` claim will be used to locate training data.

   :reqjson array input: Array of elements to predict on.
   :reqjson array training_data: Optinal, array of training data, if no `dsl`
      is required the field is required.

   :status 200: request succeeded
   :status 400: The server cannot or will not process the request due to an
      apparent client error

   Note, that :code:`training_data` is optional if there is a :code:`dsl`
   claim in the jwt content.

   .. sourcecode:: http

      POST /v1/project/example-project/model/example-model/predict HTTP/1.1
      Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cC... 
      Content-Type: application/json
      Content-Length: 517
      
      {
          "input": [{
              "text": "Taxa receipt"
          }, {
              "text": "Business lunch"
          }],
          "training_data": [{
              "text": "Taxa fare",
              "acount": 6750
          }, {
              "text": "Lunch with Visma",
              "acount": 31656
          }]
      }


   Note, that the output format depend on the model, and thus the response
   below is just an example.

   .. sourcecode:: http

      HTTP/1.1 200 OK
      Vary: Accept
      Content-Type: application/json

      {
          "output": [{
              "label": {
                  "account": 6750
              },
              "probability": 0.2
          }, {
              "label": {
                  "account": 31656
              },
              "probability": 0.2
          }]
      }

Datasets
--------

.. http:post:: /v1/project/:project/datastore/:key
   :synopsis: Upload dataset to use with project

   Upload a dataset and prepare it for usage with the :code:`project`. It the
   dataset already exists it will be overwritten.

   :reqjson array training_data: Array of training data for the project.
   :reqjson int expire: Expire the data set at unix time stamp, the dataset
      will be deleated at this point.

   :status 200: Request succeeded
   :status 400: The server cannot or will not process the request due to an
      apparent client error

   .. sourcecode:: http

      POST /v1/project/example-project/datastore/customer_214324 HTTP/1.1
      Authorization: Basic QWxhZGRpbjpPcGVuU2VzYW1l
      Content-Type: application/json
      
      {
          "expire": 1477312847,
          "training_data": [{
              "text": "Taxa fare",
              "acount": 6750
          }, {
              "text": "Lunch with Visma",
              "acount": 31656
          }]
      }

   .. sourcecode:: http

      HTTP/1.1 200 OK
      Vary: Accept
      Content-Type: application/json

      {
          "auth_header": "Bearer pPcGVuU2VzYW...",
          "expire": 1477312847
      }

.. http:delete:: /v1/project/:project/datastore/:key
   :synopsis: Delete dataset from autosuggest storage

   :status 202: request succeeded

.. http:get:: /v1/project/:project/datastore/:key
   :synopsis: Get meta data about the dataset, the dataset itself will not be returned

   :status 200: request succeeded
