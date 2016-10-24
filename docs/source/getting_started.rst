Getting started
===============
The machine learning team team builds and hosts machine learning
solutions used for automated decision making within Visma's line of ERP
systems. The machine learning models are available via a modern :ref:`REST
api<restapi-label>` that will be described in detail later in this document.

A minimal example
-----------------
So we have a consumer(a Visma ERP) -- we'll use e-conomic in this example --
that wants to map text entries to general ledger accounts. They contacted
our team about the problem and now our data science team have developed and
uploaded a model that maps text to general ledger accounts.

The consumer has received a set of master credentials

.. sourcecode:: none

   consumer: e-conomic
   secret:   N1YiI6ImFjY291bnRfMTIzIi

which is used to issue `JWT tokens <https://jwt.io>`_ (authorization headers)
to callers of the prediction api. JWT tokens allow e-conomic to share access
to AutoSuggest with e.g. web clients directly without revealing the master
credentials.

When e-conomic issues an auth token to an end user they set the :code:`iss`
claim, so Autosuggest can identify and verify the issuer. If the issuer is
a known consumer of Autosuggest and the signature can be verified, custom
claims (fields) in the content of the JWT token are used by Autosuggest, an
example being :code:`dsl` that describes the location of a training dataset.
Below is an example in python genereting a JWT token with the given master
credentials, this token will expire 01/01/2017.

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

The variable :code:`token` is a string :code:`eyJhbGciOiJIUzI1NiIsInR5cC...`
that an end user or e-conomic can use to authenticate against the Autosuggest
prediction related endpoints, the token is transfered in the Authorization
header and uses the Bearer schema, a request could look like this

.. sourcecode:: http

   POST /v1/project/econ-bankrec/model/heuristics HTTP/1.1
   Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cC...
   Content-Type: application/json
   Content-Length: 517

   {
       "input": [
           {
               "text": "Taxa receipt"
           },
           {
               "text": "Business lunch"
           }
       ]
   }

The response from the Autosuggest api will in this case look like this, but
the schema of the returned data is model dependent.

.. sourcecode:: http

   HTTP/1.1 200 OK
   Content-Length: 161
   Content-Type: application/json

   {
       "output": [
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

We have seen a minimal example on how Autosuggest can be used, but in practice
the location and size of training data introduces some problems. That we will
discuss below.


Locating training data
----------------------

When predictions are requested, AutoSuggest needs training data to train the
model. The training data can be part of the request or the JWT token can hold
a URI for the dataset. Examples on DataSet Locations (dsl) are

- :code:`http://user:pass@econ.com/asgtdata/123e4567-e89b-12d3-a456-42665544`
- :code:`datalake://companies(1423413)/generalledgertransactions?$top=100`
- :code:`autosuggest://econ-bankrec/account_2314`

The schema defines how Autosuggest will locate and retrieve the dataset, we
call these schema connector plugins for *data connectors*.
AutoSuggest develops new data connectors as needed based on consumer
requirements.
In general AutoSuggest does not perform ETL - but rely on clients to prepare
data for training and prediction - but the system is flexible when it comes to
retrieving the data sets.
At present AutoSuggest is able to access data sets stored with us - or data
sets made available through en endpoint in the Visma Datalake.

Storing data with Autosuggest
-----------------------------

The data connector for the :code:`autosuggest` schema will use Autosuggest's
own dataset storage solution. Master credentials are used to upload datasets
to the Autosuggest dataset storage solution.

The autosuggest dataset storage solution optimzes the uploaded datasets for
later predictions, so prediction requests using training data stored with
Autosuggest will answer faster than any other dataset source.

The usage of the Autosuggest dataset storage solution are documented in the
:ref:`REST api<restapi-label>` section.
