# Case Study: Helicopter Racing League

The case study can be found [here](https://services.google.com/fh/files/blogs/master_case_study_helicopter_racing_league.pdf).

## Solution Concept

Move to a new platform and expand their usage of ML and AI managed services. As new users join the sport, move the serving content closer to their users.

## Existing Technical Environment

HRL is a public cloud first company with the mission-critical applications running in the current public cloud provider. Video editing is done at the race tracks and the content is endcoded and trascoded in the cloud. Enterprise-grade connectivity and local compute is provided by truck-mounted mobile data centers.

* Existing content is stored in an object storage service on their existing public cloud
provider.
* Video encoding and transcoding is performed on VMs created for each job.
* Race predictions are performed using TensorFlow running on VMs in the current public cloud provider.

## Business Requirements

HRL owner's want to `expand predictive capabilities` and `reduce latency for new markets/customers`.

* Support ability to `expose the predictive models to partners`.
* `Increase predictive capabilities during and before races`: <-- Sounds like Machine Learning
    * Race results
    * Mechanical failures
    * Crowd sentiment
* Increase telemetry and create additional insights.
* `Measure fan engagement with new predictions`.
* `Enhance global availability and quality of the broadcasts`.
* `Increase the number of concurrent viewers`. <-- Scale
* `Minimize operational complexity`. <-- Managed Services as much as possible
* Ensure compliance with regulations.
* Create a merchandising revenue stream.

## Technical Requirements

* Maintain or increase prediction throughput and accuracy.
* `Reduce viewer latency`.
* `Increase transcoding performance`.
* Create real-time analytics of viewer consumption patterns and engagement.
* Create a data mart to enable processing of large volumes of race data.

## Executive Summary

We listen to our fans, and they want enhanced video streams that include predictions of events within the race (e.g., overtaking). Our current platform allows us to predict race outcomes but lacks the facility to support real-time predictions during races and the capacity to process season-long results.

## My Thoughts

There are differnet types of architectures to achieve the goals outlines in the Case Study. Below are some of my thoughts on what services to use.

Goals
* `Reduce viewer latency`
* `Minimize operational complexity`

Solutions
* Make use of the CDN to enhance global availability
* Use GCS which is a global resource to upload videos and

> Content Delivery Network

* Enhance global availability and quality of the broadcasts.
* CDN can help serve content closer to the user and meet the business goals by `reducing latency for new customers.`

> Google Cloud Storage

* Existing content is stored in an object storage service on their existing public cloud provider.

> Pub/Sub

* Create real-time analytics of viewer consumption patterns and engagement.

> BigQuery

* Create a data mart to enable processing of large volumes of race data.
* Create real-time analytics of viewer consumption patterns and engagement.
* Is the data warehouse.

> Datastore

* NoSQL database to house the data.
* Provides quick lookups

> Dataflow

* `Create real-time analytics of viewer consumption patterns and engagement`.
* Sends the data to Datastore.

> [Transcoder API](https://cloud.google.com/transcoder/docs/concepts/overview)

* Make use of the transcoder API to `increase transcoding performance`.
* Transcoder API can help configure low-level encoding parameters like bitrate for `quality of videos`.

> Video Intellignece API

* `Increase predictive capabilities during and before races`
* [Highlights of Video Intelligence API](https://www.youtube.com/watch?v=mDAoLO4G4CQ)
* Create real-time analytics of viewer consumption patterns and engagement.

> TesnorFlow with Compute

* Use Machine learning and TensorFlow to increase predictions
* TesnorFlow can be deploy on Compute Engine or on GKE. Since we want to be more developers vs operations, lean towards GKE and containers.


## Diagrams
Build a streaming video analytics pipeline:
![](https://cloud.google.com/architecture/images/build-streaming-video-analytics-pipeline-01.svg)

Processing User-generated content using Video Intelligence and Cloud Vision API
![](https://cloud.google.com/architecture/images/processing-architecture.svg)

Vidoe Transcoder
![](https://camo.githubusercontent.com/9112c0c92e2d56b55380def1de257c61568600d5391579cf94a597ba1a74a4f4/68747470733a2f2f726f636b6574736561742d63646e2e73332d73612d656173742d312e616d617a6f6e6177732e636f6d2f6a7570697465722d7472616e73636f64652d6469616772616d2e706e67)

[Architecture of a machine-learning system for near real-time item matching](https://cloud.google.com/architecture/real-time-item-matching?hl=en)
![](https://cloud.google.com/architecture/images/scann-architecture.svg)