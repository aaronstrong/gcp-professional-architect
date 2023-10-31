# [Big Data Lifecycle](https://cloud.google.com/architecture/data-lifecycle-cloud-platform)

The data lifecycle has four steps.
| Ingest | Store | Process & Analyze | Explore & Visualize |
| -------|-------|-------------------|---------------------|
| The first stage is to pull in the raw data, such as streaming data from devices, on-premises batch data, app logs, or mobile-app user events and analytics. | After the data has been retrieved, it needs to be stored in a format that is durable and can be easily accessed.| In this stage, the data is transformed from raw form into actionable information. | The final stage is to convert the results of the analysis into a format that is easy to draw insights from and to share with colleagues and peers. ||

![](https://cloud.google.com/architecture/images/data-lifecycle-1.svg)

## Ingest

| App | Streaming | Batch |
| --- | --------- | ----- |
| Data from app events, such as log files or user events, is typically collected in a push model, where the app calls an API to send the data to storage. | The data consists of a continuous stream of small, asynchronous messages. | Large amounts of data are stored in a set of files that are transferred to storage in bulk. |

![](https://cloud.google.com/architecture/images/data-lifecycle-2.svg)

## Store
![](https://jayendrapatil.com/wp-content/uploads/2021/02/gcp_storage_options_decision_tree.png)

![](https://cloud.google.com/architecture/images/data-lifecycle-3.svg)

### Relational Databases

#### Cloud SQL
* Regional, fully-managed relational database service for SQL server, MySQL and PostgreSQL
* Automatic replication with automatic failover, backup, and point in time recovery
* Scale manually up to 96 processor cores, more than 624 GB of RAM, and  add read replicas as needed
* Features include
     * built-in high availability
     * Automatically scale storage up to 30TB
     * Connects with GAE, GCE, GKE and BigQuery
 
#### Cloud Spanner
* Fully managed relational database, up to 99.999% availability, and unlimited scale.
* Create a Spanner instance by defining instance configuration and compute capacity
* Use query parameters to increase efficiency and lower costs
* Features include:
*   Automatic sharding
*   External consistency
*   Backup/Restore nad point in time recovery

### NoSQL Databases

### Cloud Bigtable
* Fully managed, scalable NoSQL database service for large analytical and operational workloads
* Handles large amounts of data in a key-value store and supports high read and write at low latency
* Tables stored in instances that contain up to 4 nodes, located in different zones
* Use cases:
    * Time-series data
    * Marketing and financial data
    * IoT data

### Firestore
* Fully managed, scalable, serverless **document database service**
* Live synchronization and offlien mode allow mulit-user, collaborative applications on mobile web
* Supports Datastore databases and DAtastore API
* Possible workloads include:
    * Live asset and activity tracking
    * Real-time analytics
    * Media and product catalog
    * Social user profiles and gaming leaderboards
 
---
 
### Datastream
* Serverless change data capture (CDC) and replication service
* Sychrnoize data across hetergenous databases and applications reliably
* Destinations can be BigQuery or Cloud storage

### Firebase Realtime Database
* Serverless NoSQL database for storing and syncing data
* Enhances collaboration among users across devices and web in real time

### MemoryStore
* In-memory service for Redis and Memcached
* Provides low latency access and high throughput for heavily accessed data

## Process & Analyze

![](https://cloud.google.com/architecture/images/data-lifecycle-4.svg)

## Explore & Visualize

# [IoT](https://cloud.google.com/iot-core/)

* Global resource
* Fully managed service to connect, manage, and ingest data from devices globally
* Device manager handle device identities, authentication, config and control
* Protocol bridge publishes incoming telemetry to Cloud Pub/Sub for processing
* Connect securely with MQTT or HTTPS
* CA signed certs to identify device ownership
* Two way device communication enables configuration and firmware updates

# [Cloud Pub/Sub](https://cloud.google.com/pubsub/architecture)

* Another Global resources
* Scales infinitely. At-least once messaging for ingestion, decoupling, etc.
* Messages can be up to 10MB and undeliverable messages are stored for 7 days
* Push mode delivers to HTTPS endpoint & succeeds on HTTP success status code
* Pull mode delivers messages to requesting clients and waits for ACK to delete
* Pay for data volume
* Min 1KB per publish/pull/pull request
* Messages are sent to a Topic and a topic sends to multiple subscriptions. New subscriptions can be added to a topic.
* ![](https://cloud.google.com/pubsub/images/wp_flow.svg)

# Cloud Dataprep

* Global resource
* Visually explore, clean and prepare data or analysis without running servers
* Data Wrangling (ad-hoc ETL) for business analysts, not IT folks
* Managed version of Trifacta Wrangler -- and managed by Trifacta, not Google
* Sources data from GCS/BQ/or file upload, formatted in CSV, JSON or relational

# Cloud Dataproc

* Zonal Resource
* Batch MapReduce processing via configurable, managed Spark & Hadoop clusters
* Handles being told to scale (add or remove nodes) even while running jobs
* Integrated with GCS, BQ, BigTable and Cloud Operations(stackdriver)
* Pay directly for underlying GCS servers used -- preemptible options
* Best for moving existing Spark/Hadoopsetups to GCP

# Cloud Dataflow

* Zonal resource
* Autoscaled & fully managed batch or stream MapReduce like processing
* Released as open source Apache Beam
* Autoscales & dynamically redistributes lagging work, mid-job, to optimize run time
* Integrated wtih Pub/Sub, Datastore, BQ, Bigtable, Cloud ML, Stackdriver
* Dataflow shuffle service for batch offloads Shuffle ops from workers for big gains

# Cloud Datalab

* Regional Resource
* Interactive tool for data exploration, analysis, visualization, and machine learning
* Uses Jupyter Notebook
* Support iterative development of data anaylsis algorithms in Python/SQL/JS
* Pay for GCE instance hosting and storing

# Cloud Data Studio

* Global resource
* Big data visualization tool for dashboards and reporting
* Meaningful data stories/presentation enable better business decision making
* Data sources include BQ, Cloud SQL, Google Sheets, Analytics 360, AdWords, DoubleClick

# Cloud Genomics

* Global resource
* Store and process genomes and related experiments
* Query complete genomics information for large research projects in seconds
* Process many genomics and experiments in parrellel
* Open industry standards like Global Alliance and Genomics and Health

## Dataflow vs Dataproc

| | Dataflow</br><img src="https://avatars.githubusercontent.com/u/59933973?s=280&v=4" width="100" height="100"> | Dataproc</br><img src="https://miro.medium.com/max/1024/1*0GUArw6GUW0M0QdTc3oWOg.png" width="100" height="100">| Cloud Dataprep</br><img src="https://miro.medium.com/max/600/0*PZBSMFQzL3TmC_wJ." width="100" height="100">|
| --- | -------------- | -------------- | -------------------|
|| Existing Hadoop/Spark apps | New data processing pipeline | UI-driven data preparation |
|| Machine Learing / Data Science Ecosystem | Unified Streaming and Batch processing | Scales on-demand |
|| Tunable cluster paramaters | Fully Managed, No-Ops | Fully managed, No-ops |
| <b>Workloads</b> |
| Great for streaming workloads | :x: | :heavy_check_mark: |  |
| Batch processing | :heavy_check_mark: | :x: | |
| Interactive processing and notebooks | :heavy_check_mark: | :x: | |
| Machine Learing with Spark ML | :heavy_check_mark: | :x: | |
| Processing for ML | :x: | :heavy_check_mark: | |
