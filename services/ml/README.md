# [AI Platform](https://cloud.google.com/ai-platform/docs/technical-overview)

* Use AI Platform to train your machine learning models at scale, to host your trained model in the cloud, and to use your model to make predictions about new data.

## Where AI Platform fits in the ML workflow

![](https://cloud.google.com/ai-platform/images/ml-workflow.svg)

### ML Workflow

* Train an ML on your data:
    * Train model
    * Evaluate model accuracy
    * Type hyperparameters
* Deploy your trained model
* Send prediction requests to your model:
    * Online prediction
    * Batch prediction (<i>for TensorFlow only</i>)
* Monitor the predictions on an ongoing basis
* Manage your models and model versions

## Components of AI Platform

### Training service
* select many different machine types to power your training jobs, enable distributed training, use hyperparameter tuning, and accelerate with GPUs and TPUs
* Submit your input data from AI platform to train using [built-in algorithm](####Built-in-Algorithm). If the built-in algorithm do not fit your use case, submit your own or build a custom container with your training application.

#### [Built-in Algorithm](https://cloud.google.com/ai-platform/training/docs/algorithms)

1. Compare the available built-in algorithms to determine if they fit your dataset and use case.
1. Format your input data for training with the built-in algorithm. Must be in CSV format with header row removed.
1. Create a storage bucket to store the training output.
1. Customize your training job.
1. Submit the training job, and view logs to monitor its progress and status.
1. When job successfully completed, you can deploy your trained model on AI platform training to set up a prediction server and get predictions on new data.

### Prediction service

* A service that allows you to serve predictions based on a trained model, whether or not the mode was trained on AI platform.

### Data Labeling service

* Request human labeling for a dataset that you plan to use to train a custom machine learning model.
* You can submit a request to label your video, image, or text data.

