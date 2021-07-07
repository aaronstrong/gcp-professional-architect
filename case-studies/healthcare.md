# Case Study: Healthcare

The case study can be found [here](https://services.google.com/fh/files/blogs/master_case_study_ehr_healthcare.pdf).

## Solution Concept

EHR Healthcare's business has been growing year over year and they need to be able to scale their environment, adapt their disaster recovery plan, and roll out new continuous deployment capabilities to update their software at a fast pace.

## Existing Technical Environment

EHR's software is currently in multiple colocations with one datacenter's lease about to expire.

Customer-facing applications are web-based and have been containerized to run on a group of Kubernetes clusters. Data is stored in a mixture of relational and NoSQL databases (MySQL, MS SQL Server, Redis, and MongoDB).

EHR is hosting several legacy file- and API-based integrations with insurance providers on-premises. These systems are scheduled to be replaced over the next several years. There is no plan to upgrade or move these systems at the current time.

Users are managed via Microsoft Active Directory. Monitoring is currently being done via various open source tools. Alerts are sent via email and often ignored.

## Business Requirements

* On-board new insurance providers as quickly as possible
* Provide a minimum 99.9% availability for all customer-facing systems.
* Provide centralized visibility and proactive action on system performance and usage.
* Increase ability to provide insights into healthcare trends.
* Reduce latency to all customers.
* Maintain regulatory compliance.
* Decrease infrastructure administration costs.
* Make predictions and generate reports on industry trends based on provider data

## Technical Requirements

* Maintain legacy interfaces to insurance providers with connectivity to both on-premises
systems and cloud providers.
* Provide a consistent way to manage customer-facing applications that are
container-based.
* Provide a secure and high-performance connection between on-premises systems and
Google Cloud.
* Provide consistent logging, log retention, monitoring, and alerting capabilities.
* Maintain and manage multiple container-based environments.
* Dynamically scale and provision new environments.
* Create interfaces to ingest and process data from new providers.

## Executive Summary

Current on-prem data center has had outages, the teams are supporting multiple environments and different technologies. Executives want to use GCP and leverage a scalable, resilient platform that can span multiple environments seamlessly and provide a consistent and stable user experience.

## My Thoughts

> Kubernetes

  * Provide a minimum 99.9% availability for all customer-facing systems.
  * Provide a consistent way to manage customer-facing applications that are
  container-based.
  * Dynamically scale and provision new environments.
  * Maintain and manage multiple container-based environments.

> Anthos

  * Maintain legacy interfaces to insurance providers with connectivity to both on-premises
    systems and cloud providers.
  * Maintain and manage multiple container-based environments.
  * Dynamically scale and provision new environments.
  * Provides a way to manage GKE cluster on-prem to manage containers that may only be accessible from on-premises.

> Cloud SQL

  * Data is stored in relational and NoSQL databases
  * Cloud SQL can host MySQL, PostGreSQL and MS SQL
  * MongoDB can be deploying from the marketplace or from GCE
  * Redis (memory store) can also be deployed from GCE

> Interconnect / Cloud VPN
  * Provide a secure and high-performance connection between on-premises systems and
    Google Cloud.
  * Interconnect provides speeds ranging from a minimum of 10Gbps to 200Gbps.
  * Partner Interconnect provides speeds from 50Mbps to 5Gbps
  * The easiest to deploy would a Cloud VPN with a max of 3Gbps

> Cloud CDN / Global Load Balancer

  * Reduce latency to all customers.
  * Deploying a CDN would help reduce latency.
  * Deploying a Global Load Balancer would also help a company hosting a SaaS based application.

> Cloud Logging (GCS / BigQuery)

  * Provide consistent logging, log retention, monitoring, and alerting capabilities.

> Cloud Monitoring

  * Provide centralized visibility and proactive action on system performance and usage.

> Pub/Sub

  * Create interfaces to ingest and process data from new providers.

> Managed Service Active Directory / GCE with AD DS / GCDS

  * Decrease infrastructure administration costs.
  * Google can host Active Directory, you can deploy it on GCE or sync user names, passwods and groups

> SSO / 2SV

  * Maintain regulatory compliance.
  * Enabling SSO and 2-Step varification to help enforce compliance

> BigQuery / DataStudio / Dataflow

  * Make predictions and generate reports on industry trends based on provider data

> Healthcare API

> VPC Service Controls

## Diagrams

HIPAA architecture design
![](https://cloud.google.com/architecture/images/hipaa-reference-architecture.png)

HIPAA Architecture Design - Shared Services VPC
![](https://cloud.google.com/architecture/images/hipaa-shared-services-vpc.png)