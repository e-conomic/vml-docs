Authentication
==============

All Autosuggest endpoints require authentication in the form of a bearer header on each request.

Say the key you have received is `348af00db8de0db6fff26b6d2c70a862`, you should include a header with it in your request, here is a simple example in Python

```python
import requests

resp = requests.post(
    ...
    headers={
        'Authentication': 'Bearer 348af00db8de0db6fff26b6d2c70a862',
    },
)
```

In case your request is improperly authenticated, you will receive the a response with the status code `401` and a payload like this:

```json
{
    "name": "Unauthorized",
    "status_code": 401,
    "description": <omitted for brevity>
}
```

