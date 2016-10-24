.. _restapi-label:

REST Interface
==============

Getting Predictions
-------------------

.. http:post:: /v1/problem/:problem/model/:model
   :synopsis: Send a new SMS

   Get a prediction for :code:`:problem` using :code:`:model`. Authorization
   with JWT token is required. If a `dsl` claim is present in the content of
   the JWT token the `dsl` claim will be used to locate training data.

   :reqjson array prediction_data: Array of elements to predict on.
   :reqjson array training_data: Optinal, array of training data, if no `dsl`
      is required the field is required.

   :status 200: request succeeded
   :status 400: The server cannot or will not process the request due to an
      apparent client error

   .. sourcecode:: http

      POST /v1/problem/example-problem/model/example-model HTTP/1.1
      Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cC... 
      Content-Type: application/json
      Content-Length: 517
      
      {
          "entries": [
              {
                  "text": "Taxa receipt"
              },
              {
                  "text": "Business lunch"
              }
          ]
      }



   .. sourcecode:: http

      HTTP/1.1 200 OK
      Vary: Accept
      Content-Type: text/javascript

      {
        "predictions": [
          {
               "label": {
                   "account": 6750,
               },
               "probability": 0.2
          },
          {
               "label": {
                   "account": 31656,
               },
               "probability": 0.2
          }
        ]
      }
