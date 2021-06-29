
## Implementation Guide

AutoSuggest relies on user feedback, referred to as examples, to make useful predictions. To integrate with AutoSuggest,
you have to upload these examples to the appropriate datasets. 

You can stream examples as they come in. This can be done when a user corrects or confirms a suggestion from AutoSuggest. 
Alternatively, you can send examples in batch. This applies when you shift an existing user to AutoSuggest and want
to use their existing data to train the AutoSuggest engine. Alternatively, you may be using AutoSuggest in an existing
batch workflow in your product. 

We designed the new AutoSuggest API for frictionless support of both streaming and batch workflows.

### Streaming

To stream examples, you need to implement two operations:

1. Create a dataset as a collection of the examples to use in the model you would like to train.
   Use either a regular create call, or an idempotent call: <br/>
   **POST /v2/datasets** or **PUT /v2/datasets/{name}**
   
2. Send individual examples; call: <br/>
   **POST /v2/datasets/{datasetName}/examples**

### Batch

Just as in streaming mode, you need to create a dataset before you send the first examples.

To send examples in batch, call: **POST /v2/datasets/{datasetName}/examples:batchCreate**

There's a limit of 100 examples or 10MiB per call.

Additionally, you should track examples you have sent us, since sending duplicate examples will deteriorate the quality 
of the suggestions. You have multiple ways to do so:

 - You can keep a cursor in your own system. 
 - You can generate a unique and stable UUID for each example you send us. We will only consider the last copy of each example we receive.
  - Alternatively, if you wish to periodically send us all examples, you can truncate the dataset at the beginning of your
batch operation.
    To do so, call: <br/>
    **DELETE /v2/datasets/{datasetName}/examples**

    Due to the overhead of this approach, we recommend you track examples you have sent and avoid truncating datasets.

## REST Reference

!!swagger-http https://raw.githubusercontent.com/e-conomic/vmlapis/master/gen/openapiv2/asgt/v2alpha.swagger.json!!