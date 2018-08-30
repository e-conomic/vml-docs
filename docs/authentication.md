Authentication
==============

All Autosuggest endpoints require authentication in the form of a bearer header on each request.

Authenticating Requests
-----------------------

Say the token you have received is `348af00db8de0db6fff26b6d2c70a862`, you should include a `Authorization` header of the type `Bearer` with it in your request, here is a few snippets demonstrating how you could achieve setting the header correctly.

**cURL**
```shell
$ curl --header "Authorization: Bearer 348af00db8de0db6fff26b6d2c70a862" ...
```

**Python**
```python
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

Obtaining the Token
-------------------

There is currently no self service way of obtaining a token for use in the autosuggest products, the only way to obtain one is to contact the Product Owner of the VML products, [Claus Dahl](mailto:claus.dahl@visma.com), and ask for one.
