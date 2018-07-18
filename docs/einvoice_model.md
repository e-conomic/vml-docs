Electronic Invoice Line Model
=============================

<What it does...>

Schema
------

The base schema of the Electronic Invoice Line is the following fields:

- `issue_date`: The invoice timestamp
- `currency`: The name of the currency as a string
- `supplier_id`: The id of the supplier
- `supplier_global_id`: The global id of the supplier
- `customer_ref`: The reference of the customer
- `total`: The total of the invoice
- `line_text`: The text of the invoice line
- `line_id`: The id of the line

As json, this could look like:

```json
{
    "issue_date": "YYYY-MM-DD'T'hh:mm:ss'Z'",
    "currency": "",
    "supplier_id": "",
    "supplier_global_id": "",
    "customer_ref": "",
    "total": 10,
    "line_text": "",
    "line_id": "",
}
```

When calling the service API, the schema looks like this:

```json
POST /model/electronic-invoice-line/v1
Authorization: Bearer secret-access-token
{
    "inputs": {
        "issue_date": "YYYY-MM-DD'T'hh:mm:ss'Z'",
        "currency": "",
        "supplier_id": "",
        "supplier_global_id": "",
        "customer_ref": "",
        "total": 10,
        "line_text": "",
        "line_id": "",
    },
    "targets": ["target0", "target6"]
}
```

