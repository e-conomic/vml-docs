.. _restapi-label:

REST Interface
==============
foobar


Getting Predictions
-------------------

This is the text

.. http:post:: /v1/(problem)

   Get a prediction for the problem based on the upload prediction data.

   **Example request**:

   .. sourcecode:: http

      POST /v1/econ-example-problem HTTP/1.1
      Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cC... 
      Content-Type: application/json
      Content-Length: 517
      
      {
          "prediction_data": [
              {
                  "text": "Taxa receipt"
              },
              {
                  "text": "Business lunch"
              }
          ]
      }


   **Example response**:

   .. sourcecode:: http

      HTTP/1.1 200 OK
      Vary: Accept
      Content-Type: text/javascript

      [
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

   :query sort: one of ``hit``, ``created-at``
   :query offset: offset number. default is 0
   :query limit: limit number. default is 30
   :reqheader Accept: the response content type depends on
                      :mailheader:`Accept` header
   :reqheader Authorization: optional OAuth token to authenticate
   :resheader Content-Type: this depends on :mailheader:`Accept`
                            header of request
   :statuscode 200: no error
   :statuscode 404: there's no user


Uploading Datasets
------------------
TODO
