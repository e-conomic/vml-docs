.. _restapi-label:

REST Interface
==============

Getting Predictions
-------------------

.. http:post:: /v1/project/:project/model/:model
   :synopsis: 

   Get a prediction for :code:`:project` using :code:`:model`. Authorization
   with JWT token is required. If a `dsl` claim is present in the content of
   the JWT token the `dsl` claim will be used to locate training data.

   :reqjson array input: Array of elements to predict on.
   :reqjson array training_data: Optinal, array of training data, if no `dsl`
      is required the field is required.

   :status 200: request succeeded
   :status 400: The server cannot or will not process the request due to an
      apparent client error

   .. sourcecode:: http

      POST /v1/project/example-project/model/example-model HTTP/1.1
      Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cC... 
      Content-Type: application/json
      Content-Length: 517
      
      {
          "input": [{
              "text": "Taxa receipt"
          }, {
              "text": "Business lunch"
          }]
      }



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
