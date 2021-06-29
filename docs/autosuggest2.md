# AutoSuggest 2.0

## Quick start

AutoSuggest enables you to learn user behavior and use that to assist your users and improve your user experience.
Since most of our customers use this to improve transaction processing, the API is geared towards transaction data - but it's easy to use AutoSuggest for more general text prediction problems also. 

Here's a quick guide

1. Define a new dataset using the [:create call](#typecreate) - choose the type of transaction that best resembles your data
2. Build out the dataset by adding samples to it using the [:append call](#typenameappend)
3. AutoSuggest automatically trains an ML model - when the performance is [good enough](#typenameinfo), 
4. Implement the prediction call and improve your user experience

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

2. As required by your app, request predictions from AutoSuggest. Given an input sample, ask for a prediction of targets. AutoSuggest will return with a prediction - and a confidence score indicating model belief in the prediction given. You should filter AutoSuggest's predictions based on the confidence score - a low score means the prediction is of low quality. For more on this - please read the section on [quality metrics](#quality)
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
   target_values: [{name: 'My Target Name', value: 'A value'},...],
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
https://api.stag.asgt.visma.ai/v1/
```

So in our staging environment, the full URL for the bank:create call is `https://api.stag.asgt.visma.ai/v1/bank:create`

The portal, our web front for user and token manegement, metrics dashboards, sample code and other developer tools, is at
```
https://portal.stag.vml.visma.ai/v1/
```

#### Production

Use this API for, you know, production use - and real customer data

```
https://api.prod.asgt.visma.ai/v1/
```

So in our production environment, the full URL for the bank:create call is `https://api.prod.asgt.visma.ai/v1/bank:create`

The portal, our web front for user and token manegement, metrics dashboards, sample code and other developer tools, is at
```
https://portal.vml.visma.ai/
```

### Authentication

For now, we refer to [Smartscan's documentation on authentication](/smartscan/#authentication) - AutoSuggest 2.0 shares this scheme

### API methods

The entire API is available in three flavors, `bank`, `scanned-invoice`and `electronic-invoice-line`
In all methods below - replace &lt;type&gt; with one of the three model types.
Except for the `:info` 

#### /&lt;type&gt;:create

Creates a new named dataset. You may optionally include a first patch of training samples to the dataset on creation. 
Names of datasets are local to the consumer _and_ the model type. So the bank dataset `foo` is distinct from the scanned-invoice dataset `foo`. 

##### Summary of request body
Samples left out for brevity
```json
{
    name: 'a-unique-string', 
    targets: ['names', 'of', 'target', 'variables']
    tags: ['atag', 'anothertag'],
    retention_policy: {max_days: 30},
    samples: [...]
}
```

The retention policy is based on sample _submission_ date, i.e. the date you created the dataset or appended the samples
- not any information contained in the sample definition. 

Since dataset names appear as path fragments in e.g. the `info` request and the `suggest` request 
they should be `/`-free path fragments. If you limit yourself to `[a-z,0-9,-]` you should be safe.

#### /&lt;type&gt;/&lt;name&gt;:append

Appends samples to a data set

##### Summary of request body
Samples left out for brevity

```json
{
    samples: [...]
}
```

##### Avoid duplicates

You should take care to never append the same samples twice - as this will spoil the statistics of the dataset - and influence the quality of the model. Since we have no way of knowing whether the duplicate is _real_ or a mistake - we can't correct for duplicates - and the confidence score we return is likely to be skewed. 

#### /&lt;type&gt;/&lt;name&gt;:suggest

Make predictions against a dataset - you may ask for predictions against a list of entries of the type chosen. 
You may - optionally - ask for multiple answers - useful in certain UX scenarios (e.g. filling lists - or getting a higher throughput)

The inputs should be in the same format as the `data` element for the dataset samples.

##### Summary of request body
Inputs left out for brevity

```json
{
    inputs: [...],
    options: {
        suggestion_limit: 2,
    }
}
```

##### Prediction response

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

If you call the suggest API before a model has been trained - see the [training policy](#retraining-policy) - the suggest API will return 404 - since a model was not found. 

You should pick a confidence threshold that balances the number of acceptable responses with prediction quality - the higher threshold
you pick the higher the precision of the model will be - but the lower the number of predictions provided above the threshold.
Learn more about [prediction quality](#quality)

AutoSuggest may return less than the desired number of answers if we can't credibly return any. 

#### /&lt;type&gt;:delete

Delete datasets - either by name, or by tag. Deleting a tag deletes _all_ datasets of the relevant type with the given tag. 
Use this to destroy all data for e.g. a particular customer
Note, though that this is still filtered by &lt;type&gt; - so you can only delete models for one &lt;type&gt; at a time

##### Summary of request body
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


#### /&lt;type&gt;/&lt;name&gt;:info

Get basic health info about a particular dataset. Size of set, last update, and model training status

This is the API's only `GET` request. So no request body....

##### Example output

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
    },
    model: {
        version: '1592208247596916541',
        createdAt: '2020-06-15T08:04:54.082567Z'
        datasetSize: 47,
		trainingSize: 37,
		confidenceScores: [
			{
				target: 'account',
				metrics: [
					{
						precision: 0.8,
						confidence: 0.62,
						answerRate: 0.83
					},
					{
						precision: 0.9,
						confidence: 0.68,
						answerRate: 0.53
					},
					{
						precision: 0.95,
						confidence: 0.82,
						answerRate: 0.23
					}
				]
			}
		]        
    }
}
```

The size returned is the number of samples in the dataset in the window defined by the retention policy. For a discussion of the confidence scores, please read the next section, on prediction quality.

### Prediction quality

All predictions from AutoSuggest are accompanied by a confidence score. The confidence score is a way to measure the qualit of the prediction. Generally speaking, when the confidence is higher, the answer is more likely to be correct. 
To present your users with reliable predictions, you should filter out (i.e. simply ignore) answers below an acceptable confidence. 

Picking a good cutoff threshold is a bit of a trial and error process. The higher number you choose, the better the quality of the predictions you're showing, but conversely you're also providing less prediction output to the user. What the right tradeoff is, is a matter of user preference, UX approach, and the specific use case you're using AutoSuggest for. 

#### Validation test results

To provide some guidance on the tradeoff, the [info endpoint](#typenameinfo) outputs a choice of the tradeoffs. During training, AutoSuggest runs a validation test, and computes the performance when demanding predictions that are respectively `95%`, `90%` and `80%` correct. For each target you're predicting and for each confidence level, the API outputs a confidence cutoff, that corresponded to this quality level in the validation test. AutoSuggest also outputs the answer rate, i.e. the percentage of predictions that have a confidence above the cutoff. 

Weighing precision and answer rate against each other is a crucial step in designing a machine learning application. 

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

## REST Reference

!!swagger-http https://raw.githubusercontent.com/e-conomic/vmlapis/master/gen/openapiv2/asgt/v1.swagger.json!!
