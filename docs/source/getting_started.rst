Getting started
===============
The Autosuggest team builds and hosts machine learning solutions used for
automated decision making within Visma's line of ERP systems. The machine
learning models are available via a moden :ref:`REST api<restapi-label>` that
will be described in detail later in this document.

A minimal example
-----------------
So we have a consumer(a Visma ERP) -- e-conomic -- that wants to map text
entries to general ledger accounts. They contacted our team about the problem
and now our data science guys have developed and uploaded a model that maps
text to general ledger accounts.

The consumer has recieved a pair of master credentials

.. sourcecode:: none

   consumer: e-conomic
   secret:   N1YiI6ImFjY291bnRfMTIzIi

which is used to issue `JWT tokens <https://jwt.io>`_ (authorization headers)
to end users. When e-conomic issue a auth token to an end user it is important
that they set the :code:`iss` claim, so Autosuggest can identify and verify
the issuer. If the issuer is a known consumer of Autosuggest and the signature
can be verified custom claims in the content of the JWT token are used by
autosuggest, an example being :code:`dsl` that describes the location of a
dataset. Below is an example in python genereting a JWT token with the
given master credentials, this token will expire 01/01/2017.

.. sourcecode:: python

   import jwt
 
   secret = 'N1YiI6ImFjY291bnRfMTIzIi'
   content = {
       "iss": "e-conomic",  # Consumer
       "exp": 1483228800,
       # "dsl": http://user:pass@econ.com/asgtdata/123e4567-e89b-12d3-a456-42665544 
       # DataSetLocation, will allow the requester
       # to use a dataset located externally
   }
   # decode is used to get the token as a utf-8 string instead of bytes
   token = jwt.encode(content, 'N1YiI6ImFjY291bnRfMTIzIi').decode()
   print(token)

the variable :code:`token` is a string :code:`eyJhbGciOiJIUzI1NiIsInR5cC...`
that an end user or e-conomic can use to authenticate against the autosuggest
prediction related endpoints, the token is transfered in the Authorization
header and uses the Bearer schema, a request could look like this

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
       ],
       "training_data": [
           {
               "account": 6750,
               "text": "Taxa to airport"
           },
           {
               "account": 31656,
               "text": "Lunch with staff"
           }
       ]
   }

The response from the autosuggest api will in this case look like this, but it
the schema of the returned data is model dependend.

.. sourcecode:: http

   HTTP/1.1 200 OK
   Content-Length: 161
   Content-Type: application/json
   
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

We have seen a minimal example on how autosuggest can be used, but in practice
the amount of and location to training data introduces some problems. That we
will discuess below.





Connecting to data sources
--------------------------
The call above could be made from a browser by an enduser and we need more data

Therefore some endusers experience Autosuggest as slow. For that reason you
have set up a webserver in you datacenter that is to host the data sets.


Storing data with Autosuggest
-----------------------------

The example above works fine, but to get better predictions we need more
training data, alot more training data. For that reason we have a solution for
storeing training data in Autosuggest.

so that loading in training data into models happens under optimal
circumstances. Furthermore we schema validate the training data set on the
time of upload so that this (time expensive) step is not done at the time of
the prediction request.



What’s next?
------------
Get in touch or keep reading the documentation
