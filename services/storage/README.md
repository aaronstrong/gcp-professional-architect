# GCP Storage Options

Storage Flowchart

![](https://jayendrapatil.com/wp-content/uploads/2019/01/Google-Cloud-Storage-Options-Flowchart.png)

Compare Storage Options
![](../../images/compare-storage-in-gcp.png)

## Google Cloud Storage
* Durable and highly available object storage (like AWS S3)
* Supports unstructered data storage
* Data encryption in-flight and at rest
* Unlimited storage with no minimum object size with a maximum unit size of 5 TB per object
* Worldwide accessibility and worldwide storage locations.
* Low latency (time to first byte typically tens of milliseconds).
* High durability (99.999999999% annual durability).
* Geo-redundancy if the data is stored in a multi-region or dual-region.
* <u>Usage Patterns</u>
    * Images, pictures, and videos
    * Objects and blobs
    * Unstructured data
    * Long term storage for archival or compliance
* Simple [pricing model](https://cloud.google.com/storage/pricing)
    * Network ingress and data transfer within a region is free
    * Network egress charges apply and vary by destination
* All storage classes accessed through the same APIs
* [Four Storage Classes](https://cloud.google.com/storage/docs/storage-classes)


|  Storage Class | Min. duration | Monthly availability | Usecase |
|  ---  |  ---  |  ---  | --- |
| `STANDARD` | None      | * >99.99% in multi-regions and dual regions<br> * 99.00% in regions  | Best for frequently accessed data ("hot" data) |
| `NEARLINE`  | 30 days      | * 99.95% in multi-regions and dual regions<br> * 99.9% in regions | Lower availability, a 30-day min. storage duration like data backup, long-tail multimedia, and data archiving |
|  `COLDLINE`| 90 days      | * 99.95% in multi-regions and dual-regions<br> * 99.9% in regions      | Mainly for backup or archiving purposes |
| `ARCHIVE` | 365 days      | * 99.95% in multi-regions and dual-regions<br> * 99.9% in regions | Low-cost highly available for data archive, online backups and DR

![](https://miro.medium.com/max/700/1*Npk19yOdpcVkkATP6AkIkQ.jpeg)

## [Cloud Bigtable](https://cloud.google.com/bigtable/docs/overview)

* Scales to billions of rows and thousands of columns to store terrabytes/petabytes of data.
* Ideal for storing very large amounts of single-keyed data with very low latency.
* Ideal data source for MapReduce operations
* What it's good for:
    * Internet of Things data
    * Graph data
    * Financial data like transaction history, stock prices
    * Marketing data like purchase history
* Bigtable is not a relational database.
* Does not support SQL queries, joins, or multi-row transactions.
* Not transactional and does not support ACID
* Eventual consistency

## Cloud SQL

* provides fully managed, <u>relational SQL databases</u>
* offers MySQL, PostgreSQL, MSSQL databases as a service
* manages OS & Software installation, patches and updates, backups and configuring replications, failover however needs to select and provision machines
* Usage
    * OLTP workloads
    * Relational database
* What it's good for:
    * Websites, blogs, and MCS
    * BI Apps
    * CRM, eCommerce