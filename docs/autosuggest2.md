# AutoSuggest 2.0

AutoSuggest 2.0 is a complete rewrite of AutoSuggest - it is not backward compatible with the previous versions - but very similar in spirit. 

!!! Beta release
| AutoSuggest 2.0 is currently in beta. This means we believe that the API will stay in it's current form

## New in AutoSuggest 2.0

* Incremental dataset updates
* One unified JSON API
* Authentication aligned with Smartscan
* Brand new efficient training and prediction engines
* Developer portal with
    * Self Signup
    * Team access control
    * Built in quality metrics

## Overview of the new training loop

AutoSuggest 2.0 simplifies the ML process to three easy steps

### Before you predict

To enable a new type of prediction from AutoSuggest you need to 

1. Define a dataset. A dataset should contain
    * A unique name
    * One or more tags - you use tags to identify the data owner (for deletion and GDPR management)
    * A list of targets
    * A *retention policy* specifiying what data to use for prediction as more and more samples roll in
    * Optionally, the first data samples to train a model on

### Predict, improve loop

With a defined dataset in hand, you are ready to implement the main loop of AutoSuggest. 

2. As required by your app, request predictions from AutoSuggest. Given an input sample, ask for a prediction of targets. AutoSuggest will return with a prediction - and a confidence score indicating model belief in the prediction given. You should filter AutoSuggest's predictions based on the confidence score - a low score means the prediction is of low quality. For more on this - please read [TBA]
3. As you get user feedback on the suggestions from AutoSuggest - append the input sample, along with the *true* values for the targets to the dataset

That's it! There are no more steps involved - no need to set up a training loop - no need to do any additional ETL to provide training data for the algorithm.

## Input

The AutoSuggest models come in three flavors - they support different fields based on different data available on different types of transaction.

The three types of model are

* Bank Transactions - Predictions based on information available in a standard bank transaction export
* Scanned invoices - Predictions based on information available from Smartscan (i.e. document text)
* Electronic Invoice Lines - Predictions based on information available in electronic invoices

### Full schema

The full schema looks like below - but for each model only a subset of the fields are used

```json
{
   target_values: [{target: 'My Target Name', value: 'A value'},...],
   data: {
       transaction: {
           text: 'line text',
           amount: 17.5
       },
       invoice: {
           issue_date: '2018-07-18T12:32:55Z' ,
           currency: 'DKK',
           supplier: {
               id: '123',
               name: 'Acme Inc',
               global_id: 'DK30402499',
           }
           customer_ref: 'yourref',
           text: 'If I was a scanned invoice, this would be the full text of me',
           total: 12.5
       },
       invoice_line: {
           text: 'Line product text description',
           item_id: 'A product ID if one exists'
       }
   }
}
```

Here's how the fields are used per model type - a `*` indicates all fields included for a object-valued key in the json example above

| Field                    | `electronic-invoice-line` | `bank`  | `scanned-invoice` |
|--------------------------|---------------------------|---------|-------------------|
| `transaction.*`          |                           | *       |                   |
| `invoice.issue_date`     |  *                        |         |  *                |
| `invoice.text`           |                           |         |  *                |
| `invoice.*` except `text`|  *                        |         |                   |
| `supplier.*`             |  *                        |         |                   |
| `invoice_line.*`         |  *                        |         |                   |

The prediction targets have the same form for all the APIs. They are always string valued categories - i.e. the `value` property should be a string - even if the value is encoded differently in your application. 

The supported data types are the following

### Scanned Invoice

This is the simplest type of data sample. On the input side 

#### Example
```json
    {
        invoice: {
            'text': 'OCR text of a document - or other text you have on record'
        }
    }
```

### Bank Transaction

* Description text for the bank transaction
* Amount - presented as a floar

#### Example
```json
    transaction: {
        {
            text: 'Bank statement text info', 
            amount: 17.50}
    }
```

### Electronic Invoice Line

An aggregate of invoice level and line level information

#### Invoice fields
* Issue date - presented as a timestamp in text format
* Customer Reference - i.e. any data identifying recipient could be `Invoice.AccountingCustomerParty.Party.PartyName` in the Peppol specifications
* Total - presented as a float
* Currency - standard three letter code
#### Supplier fields
* Supplier ID - your local database of the supplier
* Supplier name
* Global Supplier ID - e.g. the official VAT number of supplier
#### Invoice line fields
* Line text - Could be Item.Description and/or InvoiceLine.Item.Name and/or InvoiceLine.Item.InvoicedQuantity
* Line ID - A global product id - eg. InvoiceLine.Item.StandardItemIdentification in the Peppol specifications

Please be aware that you need to submit _each_ line as an individual sample - and for each sample, you need to present
the invoice level information. 
This denormalization aligns the data better with the data science process internally in AutoSuggest.

#### Example
```json
{
    invoice: {
        issue_date: “2018-07-18T12:32:55Z” 
        customer_ref: 'roadrunner@acme.inc',
        currency: 'DKK',
        total: 99.99,
        supplier: {
            id: '123',
            name: 'Acme Inc',
            global_id: 'DK30402499',
        }
    },
    invoice_line: {
        text: '1 TNT prevention device',
        line_id: '12345',
    }
}
```

## API 

### Environments

Two environments are available. Staging and production. 

#### Staging

Use this environment for development, and testing - even automated integration tests. API base url is

```
https://api.stag.asgt.visma.ai/
```

The portal, our web front for user and token manegement, metrics dashboards, sample code and other developer tools, is at
```
https://portal.stag.vml.visma.ai/
```

#### Production

!!! Future
| The beta API will be available in production in june 2020.

Use this API for, you know, production use - and real customer data

```
https://api.asgt.visma.ai/
```

The portal, our web front for user and token manegement, metrics dashboards, sample code and other developer tools, is at
```
https://portal.vml.visma.ai/
```

### Authentication

For now, we refer to [Smartscan's documentation on authentication](smartscan#Authentication) - AutoSuggest 2.0 shares this scheme

### API methods

The entire API is available in three flavors, `bank`, `scanned-invoice`and `electronic-invoice-line`
In all methods below - replace &lt;type&gt; with one of the three model types.

### /&lt;type&gt;:create

Creates a new named dataset. You may optionally include a first patch of training samples to the dataset on creation. 
Names of datasets are local to the consumer _and_ the model type. So the bank dataset `foo` is distinct from the scanned-invoice dataset `foo`. 

#### Summary of request body
Samples left out for brevity
```json
{
    name: 'a-unique-string', 
    tags: ['atag', 'anothertag'],
    retention_policy: {max_days: 30},
    samples: [...]
}
```

The retention policy is based on sample _submission_ date, i.e. the date you created the dataset or appended the samples
- not any information contained in the sample definition. 

Since dataset names appear as path fragments in e.g. the `info` request and the `suggest` request 
they should be `/`-free path fragments. If you limit yourself to `[a-z,0-9,-]` you should be safe.

### /&lt;type&gt;/&lt;name&gt;:append

Appends samples to a data set

#### Summary of request body
Samples left out for brevity

```json
{
    name: 'a-unique-string', 
    samples: [...]
}
```

#### Avoid duplicates

You should take care to never append the same samples twice - as this will spoil the statistics of the dataset - and influence the quality of the model. Since we have no way of knowing whether the duplicate is _real_ or a mistake - we can't correct for duplicates - and the confidence score we return is likely to be skewed. 

### /&lt;type&gt;/&lt;name&gt;:suggest

Predict against a dataset - you may ask for predictions against a list of entries of the type chosen. 
You may - optionally - ask for multiple answers - useful in certain UX scenarios (e.g. filling lists - or getting a higher throughput)

The inputs should be in the same format as the `data` element for the dataset samples.

#### Summary of request body
Inputs left out for brevity

```json
{
    inputs: [...],
    name: 'a-unique-string',
    options: {
        suggestion_limit: 2,
    }
}
```

#### Prediction response

The prediction response looks like the following example
```json
{
    predictions: [
        {targets: [
            {
                name: 'account',
                candidates: [
                    {
                        value: '2750', 
                        confidence: {value: 0.0723544955}
                    },
                    {
                        value: '3110', 
                        confidence: {value: 0.0710597634}
                    }
                ]
            }
        ]}
    ],
    model: {
        'version': '1592208247596916541'
    }
}
```

You should pick a confidence threshold that balances the number of acceptable responses with prediction quality - the higher threshold
you pick the higher the precision of the model will be - but the lower the number of predictions provided above the threshold.

AutoSuggest may return less than the desired number of answers if we can't credibly return any. 

### /&lt;type&gt;:delete

Delete datasets - either by name, or by tag. Deleting a tag deletes _all_ datasets of the relevant type with the given tag. 
Use this to destroy all data for e.g. a particular customer
Note, though that this is still filtered by &lt;type&gt; - so you can only delete models for one &lt;type&gt; at a time

#### Summary of request body
Either
```json
{
    name: 'a-unique-string',
}
```

Or

```json
{
    tag: 'a tag',
}
```


### /&lt;type&gt;/&lt;name&gt;:info

Get basic health info about a particular dataset. Size of set, last update, and model training status

This is the API's only `GET` request. So no request body....

#### Example output

```json
{
    dataset: {
        consumer: 'vml',
        name: 'foobaz',
        type: 'scanned-invoice',
        targets: ['account'],
        retentionPolicy: {
            maxDays: '90'
        },
        createdAt: '2020-06-15T08:02:20.839630Z',
        updatedAt: '2020-06-15T08:02:20.927418Z',
        size: '47'
    },
    model: {
        version': '1592208247596916541',
        createdAt': '2020-06-15T08:04:54.082567Z'
    }
}
```

The size returned is the number of samples in the dataset in the window defined by the retention policy

### Retraining policy

To avoid needless retraining on multiple append requests there's a brief timeout period on append requests before model retraining kicks in. If further data is uploaded within the timeout period - the timeout is extended - if this happens more than 5 times, a retrining is initiated. 

#### Training on create

When creating a dataset - and including data in the create request - a training session will be started within 1 minute. 
If you append data to the dataset within the first minute - an extra minute will be added to the wait up to a maximum of 5 minutes. 

#### Training on append

When you append data to a dataset - a training will be kicked off within 1 hour of the append. If you append during this time window, the training will be postponed for an additional hour - up to a maximum delay of 6 hours. 

### Debugging

In case of errors during your implementation - you may finde the GRPC headers forwarded to the JSON API useful. If you get any HTTP error response, the `grpc-message` header will contain a textual elaboration of the error. 

You may use the `info` API call to verify that your dataset is alive and well. 

