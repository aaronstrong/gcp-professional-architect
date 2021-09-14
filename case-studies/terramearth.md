# Case Study: TerramEarth

The case study can be found [here](https://services.google.com/fh/files/blogs/master_case_study_terramearth.pdf).

TerramEarth manufactures heavy equipment and they currently have 500 dealers and service centers in 100 countries.

## Solution Concept

There are 2 million TerramEarth vehicles in operation and see 20% yearly growth. Vehicles collect telemetry data from many sensors during operation. A small subset of critical data is transmitted from the vehicles in real time to facilitate fleet management. The rest of the sensor data is collected, compressed, and uploaded daily when the vehicles return to home base. Each vehicle generates 200 to 500 MBs fo data per day.

## Existing Technical Environment

TerramEarth's vehicle data aggregation and analysis infrastructure resides in Google Cloud and serves clients from all around the world. A growing amount of sensor data is captured from tehir 2 main manufactoring plans and sent to private data centers that contain their legacy inventory and logistics management systems. The private data centers have multiple network interconnects configured to Google Cloud.

Web frontend for dealers and customers is running in Google Cloud and allows access to stock management and analytics.


## Business Requirements

* Predict and detect vehicle malfunction and rapidly ship parts to dealerships for just-intime repair where possible.
* Decrease cloud operational costs and adapt to seasonality.
* Increase speed and reliability of development workflow.
* Allow remote developers to be productive without compromising code or data security.
* Create a flexible and scalable platform for developers to create custom API services for
dealers and partners.


## Technical Requirements

* Create a new abstraction layer for HTTP API access to their legacy systems to enable a
gradual move into the cloud without disrupting operations.
* Modernize all CI/CD pipelines to allow developers to deploy container-based workloads
in highly scalable environments.
* Allow developers to run experiments without compromising security and governance
requirements
* Create a self-service portal for internal and partner developers to create new projects,
request resources for data analytics jobs, and centrally manage access to the API
endpoints.
* Use cloud-native solutions for keys and secrets management and optimize for identitybased access.
* Improve and standardize tools necessary for application and network monitoring and
troubleshooting.

## Executive Summary


## My Thoughts

> GKE

* Using GKE will allow for `flexible and scalable platform for developers to create custom API services for
dealers and partners`
* Allows the developer to `Modernize all CI/CD pipelines to allow developers to deploy container-based workloads
in highly scalable environments`.

> AutoML

* Using ML to help with `Predict and detect vehicle malfunction`

> BigQuery

* Managed data warehouse that stores IoT data alongside enterprise analytics and logs.

> Datalab

* Interactive tool for large-scale data exploration, analysis and visualization.

> Dataflow

* Can handle high volume data processing pipelines for IoT scenarios.
* Dataflow is a managed Apache Beam service for processing data in multiple ways, including batch operations, extract-transform-load (ETL) patterns, and continuous streaming computation.

> IoT Core

* For device management and connection
* Uses MQTT (Message Queue Telemetry Transport) for the actual device management. Allows for constrained devices to send real-time telemetry as well as immediately receive messages sent from cloud to devices by using config management. MQTT directly connects to pub/sub.

> Pub/Sub

* Global ingestion service.
* Can act like shock absorber and rate leveller for both incoming data streams and app architecture changes.

## Diagrams

[Technical orverview of IoT](https://cloud.google.com/architecture/iot-overview?hl=en)

![](https://cloud.google.com/iot-core/images/data-management.svg)

![](https://i.stack.imgur.com/YBzeU.png)