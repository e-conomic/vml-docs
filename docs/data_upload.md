# Uploading Training Data

Submitting training data to autosuggest services is done by first creating a dataset and then uploading that dataset to AWS S3.
The dataset format depends on the service, as each service will make predictions on different kinds of data, but in general the datasets are packed into a binary format called ProtocolBuffers (generally referred to as protobuf).

When uploading the dataset, there is a S3 bucket defined as well as a path, the bucket is `asgt.dataset.{environment}` and the path is `{user_id}/{autosuggest_service_name}/{dataset_name}`.
Lets for the sake of an example say we are a small business accounting company called "Bills 'R Us", we have a customer called "Jimmy's Icecream Truck", and we really want to get predictions from the Autosuggest service "Electronic-Invoice-Line", in the "production" environment.

When building the dataset, it needs to be build in accordance with the format used by the model used by the Electronic-Invoice-Line service. We name the dataset something we can remember relates to the customer we want to predict on such as `jimmys-icecream-truck` (although an id of sorts would suffice as well). Since it is a protobuf it is required by our systems to append `.pb` to the name of the dataset, making it `jimmys-icecream-truck.pb`.

!!! Note
    When training, a number of transformations happen on the data, notably the dataset gets transformed into so-called `dataframes`, where the names of the colums are derived from the names on the fields of the data. In the case the first item in the protobuf is empty, the column names gets transformed incorrectly, and as a result the dataset does not contain any targets.

    So make sure the datasets do not contain empty lines.

With the dataset in hand, we can now upload it. Since we want to upload it to the production environment, we need to upload it to the S3 bucket called `asgt.dataset.production` with the path `bru/electronic-invoice-line/jimmys-icecream-truck.pb`, with `bru` being the username of our company account.
We use AWS access credentials provided by the VML product team - the developers behind the Autosuggest service.

Once we have uploaded the data the Autosuggest systems take over, training the model for the service with the dataset, producing as many targets as the datasets defines.

Training time depends on the size of the dataset, specifically the number of classes and the number of targets in the dataset. So if your dataset contains many classes and many targets, expect that training time can take a while.
