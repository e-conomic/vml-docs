.. _restapi-label:

REST Interface
==============


Getting Predictions
-------------------

.. http:post:: /problem/:problem/model/:model
   :synopsis: Send a new SMS

   Get a prediction for :code:`:problem` using :code:`:model`. Authorization
   with JWT token is required. If a `dsl` claim is present in the content of
   the JWT token the DataSetLocation will be used as training data for the
   call.

   :reqjson array prediction_data: Array of elements to predict on.
   :reqjson array training_data: Optinal, array of training data.

   :resjson string feedback: feedback

   :status 200: no error
   :status 404: there's no user

   .. sourcecode:: http

      POST /v1/problem/econ-example HTTP/1.1
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
        "feedback": "https://autosuggest.com/v1/problem/econ-example/model/experimental-heurestics/feedback",
        "entries": [
          {
            "post_id": 12345,
            "author_id": 123,
            "tags": ["server", "web"],
            "subject": "I tried Nginx"
          },
          {
            "post_id": 12346,
            "author_id": 123,
            "tags": ["html5", "standards", "web"],
            "subject": "We go to HTML 5"
          }
        ]
      }



Uploading Datasets
------------------
TODO
