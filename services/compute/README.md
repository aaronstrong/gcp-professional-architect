# GCP Compare Compute Options

|       | IaaS  | Containers | Containers      | PaaS     | PaaS      | FaaS      |
|  ---  |  ---  |  ---  |  ---  |  ---  |  ---  |  ---  |
|       | [GCE](#GCE)   | [GKE](#GKE)   | [Cloud Run](#Cloud-Run)     | [App Engine<br>Standard](###Standard-vs-Flexible)| [App Engine<br>Flexible](###Standard-vs-Flexible) | [Cloud<br>Functions](#Cloud-Functions)      |
| Scaling               | VM Image<br>Autoscale | Cluster      | Container<br>Fully managed<br>scale to zero  | App<br>Autoscale managed<br>scale to zero       | App or Container<br>Autoscale managed       | Function<br>Scale to zero       |
| Language Support      | Any      | Any      | Any      | Python, Node.js, Go, Java, PHP       | Python, Node.js, Go, Java, PHP, Ruby, .Net      | Python, Node.js, Go      |       
| Background Processes  | Yes      | Yes      | No      |Support for basic and manual scaling mode |Yes and SSH debug       |  No     |       
| Request Timeout       | None      | None      | 15 minutes    | 1 minute      | 60 minutes       | 9 minutes      |       
| Other features        | Persistent disks<br>Websockets<br>TPU/GPU access      | Persistent disks<br>Websockets<br>TPU/GPU access      | Serverless container    | Millisecond startup<br>No writing to local disk      |  Minutes startup<br>Able to install 3rd party binaries     | Serverless      |       
| Use Cases             | Lift&Shift<br>on-premises and monolith workloads      | Container Workloads       |Container Workloads       |  Scalable web apps<br>mobile backend apps     | Scalable web apps<br>mobile backend apps      | Event driven and data<br>processing apps      |       



# [GCE](https://cloud.google.com/compute/docs/concepts)

Google Compute Engine instances can run the public images for Linux and Windows Server that Google provides as well as private custom images that you can create or import from your existing systems.

You can choose the machine properties of your instances, such as the number of virtual CPUs and the amount of memory, by using a set of predefined machine types or by creating your own custom machine types.

### Instances and Projects

Each instance belongs to a Google Cloud Console project, and a project can have one or more instances. When you create an instance in a project, you specify the zone, operating system, and machine type of that instance. When you delete an instance, it is removed from the project.

### Instances and Storage

By default, each Compute Engine instance has a small boot persistent disk that contains the operating system. When applications running on your instance require more storage space, you can add additional storage options to your instance.

### Instances and Networking

Each network interface of a Compute Engine instance is associated with a subnet of a unique VPC network.

### Default time zone

Regardless of the region where you create your VM instance, the default time for your VM instance is Coordinated Universal Time (UTC).

### [Storage](https://cloud.google.com/compute/docs/disks)

Compute Engine offers several types of storage options for your instances. Each of the following storage options has unique price and performance characteristics:

* [Zonal persistent disk](###zonal-persistent-disk): Efficient, reliable block storage.
* [Regional persistent disk](###regional-persistent-disk): Regional block storage replicated in two zones.
* [Local SSD](###local-ssd): High performance, transient, local block storage.
* Cloud Storage buckets: Affordable object storage.
* [Filestore](###-filestore): High performance file storage for Google Cloud users.

Persistent disks are durable network storage devices that your instances can access like physical disks. The data on each persistent disk is distributed across several physical disks. Compute Engine manages the physical disks and the data distribution for you to ensure redundancy and optimal performance. Persistent disks are located independently from your virtual machine (VM) instances, so you can detach or move persistent disks to keep your data even after you delete your instances.

### Disk Types

When you configure a zonal or regional persistent disk, you can select one of the following disk types.

* <b>Standard persistent disks</b> (`pd-standard`) are backed by standard hard disk drives (HDD).
* <b>Balanced persistent disks</b> (`pd-balanced`) are backed by solid-state drives (SSD). They are an alternative to SSD persistent disks that balance performance and cost.
* <b>SSD persistent disks</b> (`pd-ssd`) are backed by solid-state drives (SSD).
* <b>Extreme persistent disks</b> (`pd-extreme`) are backed by solid-state drives (SSD). With consistently high performance for both random access workloads and bulk throughput, extreme persistent disks are designed for high-end database workloads. Unlike other disk types, you can provision your desired IOPS. For more information, see Extreme persistent disks.

# [App Engine](https://cloud.google.com/appengine/docs/flexible/python/an-overview-of-app-engine)

* Google PaaS offering for compute
* Considered a serverless option because you bring your code. You don't have to worry about underlying infrastructure.
* App Engine is a top-level container that includes the service, version and instance that make up your app
* All resources are created in a region. <b>Cannot change once deployed</b>
* Each GCP Project can contain only a single App Engine app.
* Great for microservices
* Here's a diagram that illustrates App Engine app running multiple services.

![](https://cloud.google.com/appengine/docs/images/modules_hierarchy.svg)

### Services
* Think of services like [microservices](https://en.wikipedia.org/wiki/Microservices)
* You can run whole app in a single service, or design and deploy multiple services
* Each services consists of the source code from your app

### Versions
* Quickly switch between differen versions of that app for rollbacks and testing.
* You can route to one or more specific version by migrating or [splitting traffic](###Splitting)

### Instances
* AE will scale the underlying instances to match the load

### Splitting
* Used to specify a percentage of traffic across two or more of the versions within a service.
* Allows to conduct A/B testing between versions and control over rolling out features
* Traffic splitting is applied to URLs that do not explicitly target a version.
* To disable traffic splitting, migrate all traffic to a single version
* Must choose whether to split traffic by using either an IP address or HTTP cookies.
    * Splitting by IP is easier
    * Splitting by HTTP cookies is more precise.

#### IP Splitting
* IP Splitting hashes the IP address to a value between `0-999`, and uses that number to route the request
* Limitations:
    * IP addresses are sticky, not permanent.
    * IF you need to send internal requests between apps, you should use cookie splitting

#### Cookie Splitting
* Cookie splitting, the application looks in the HTTP request header for a cookie named `GOOGAPPUID` which contains a value between `0-999`.
    * If the cookie exists, the value is used to route the request. 
    * If there is no such cookie, the request is routed randomly.

---
### [Standard vs Flexible](https://cloud.google.com/appengine/docs/the-appengine-environments#the_app_engine_environments)

<b>Use cases</b>

| Standard  | Flexible      |
|  ---  |  ---  |
| Application instances run in a sandbox, using the runtime envrionment of a supported language.  | Application instances run within Docker on GCE.      |
| Applications that need to deal with rapid scaling.      | Applications that receive consistent traffic, experience regular traffic influctions, or meet parameters for scaling up and down gradually.      |
| Support programming languages:<br>* Python 2.7-3.9<br> * Java 8, 11<br> * Node.js 10,12,14,16<br> * PHP<br> * Ruby<br> * Go  | Support programming languages:<br> * Python, Java, Node.js, Go, Ruby, PHP or <b>.NET</b>  |
| Run for free or very low cost      | Access the resources or services of your google Cloud project that reside in GCE network.      |

#### Compare Features

|  Feature   | Standard       | Flexible      |
|  ---  |  ---  |  ---  |
| Instance startup  | Seconds    | Minutes       |
| Max request timeout    | Depends on runtime and type of scaling      |  60 min      |
| Scale to zero      | Yes      | No, minimum 1 instance       |
| Modifying the runtime | No | Yes (through Dockerfile) |
| Deployment time | Seconds | Minutes |
| Background processes | No | Yes |
| SSH Debug | No | Yes |

# [GKE](https://cloud.google.com/kubernetes-engine/docs/concepts/kubernetes-engine-overview)

![](https://cloud.google.com/kubernetes-engine/images/cluster-architecture.svg)

* Container orchestrator that's managed by Google
* Powered by Kubernetes, open source cluster management system.
* Uses Google's Load-Balacing
* [Node pools](##Node-Pools) to designate subsets of nodes within a cluster for additional flexibility
* Automatic Scaling of your cluster's node instance count
* Automatic upgrades for your cluster's node software
* Node auto-repair to maintain node health and availability
* Logging and monitoring with Google's Cloud operations suite for visibility

## Cluster Types
* [**Autopilot**](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-architecture): Autopilot mode, the cluster configuration options are made for you.
* [**Standard**](https://cloud.google.com/kubernetes-engine/docs/concepts/cluster-architecture): You determine the configurations needed for your production workloads.
* [**Private Clusters**](https://cloud.google.com/kubernetes-engine/docs/concepts/private-cluster-concept): Use nodes that do not have external IP addresses. Has both a control plane private endpoint and a control plane public endpoint. Must specify a unique `/28` IP address range for the control plane's private endpoint, and you can choose to disable the control plane's public endpoint.

## Availability Type
* **Zonal Clusters** - Has a single control plane in a single zone.
    1. **Single-zone Clusters**: has a single control plane running in one zone. This control plane manages workloads on nodes running in the same zone.
    1. **Multi-zonal Clusters**: has a single replica of the control plane running in a single zone, and has nodes running in multiple zones. During upgrades or an outage, workloads still run. However the cluster, its nodes and workloads cannot be configured during this time.
* **Regional Clusters** - Has multiple replicas of the control plane, running in multiple zones in a region. Nodes can run in multiple zones or a single zone. By default, GKE replicates each node pool across three zones of the control plane's region.

### Create a zonal cluster

```bash
gcloud container clusters create `CLUSTER_NAME` \
    --release-channel `CHANNEL` \
    --zone `COMPUTE_ZONE` \
    --node-locations `COMPUTE_ZONE`,`COMPUTE_ZONE1`
```

## Node Pools

* Is a group of nodes within a cluster that all have the same configuration.
* You can resize node pools in a cluster by adding/removing nodes.
* Worker machines that run your containerized applications and other workloads
* Each node is managed from the control plane, which receives updates from each node.

### [Useful Node Pool Commands](https://cloud.google.com/kubernetes-engine/docs/how-to/node-pools#add)

Create a node Pool
```bash
gcloud container node-pools create` POOL_NAME` --cluster `CLUSTER_NAME`
```

Resize a node pool
```bash
gcloud container clusters resize `CLUSTER_NAME` --node-pool `POOL_NAME` \
    --num-nodes `NUM_NODES`
```

## Networking

* **ClusterIP**: The IP address assigned to a Service. This address is stable for the lifetime of the Service.
* **Pod IP**: The IP address assigned to a given Pod. This is ephemeral
* **Node IP**: The IP address assigned to a given node.

### Networking inside the cluster

#### IP allocation
* Each node get's an IP from the cluster's VPC. This IP is the node's connection to the rest of the cluster like to the Kubernetes API server.
* Each node has a pool of IP addresses that GKE assigns to Pods running on the node.
* Each Pod has a single IP address assigned from the Pod CIDR range on the node.
* Each Service has an IP address, called the ClusterIP, assigned from the cluster's VPC network.

#### Pods
A Pod runs one or more containers. Zero or more Pods run on a node. Each node in the cluster is part of a node pool. Pods can attach to external storage volumes and other custom resources.

Kubernetes assigns an IP address (the Pod IP) to the virtual network interface in the Pod's network namespace from a range of addresses reserved for Pods on the node (secondary addresses). A container running in a Pod uses the Pod's network namespace. All containers in the Pod see this same network interface. Each container's localhost is connected, through the Pod, to the node's physical network interface, such as `eth0`.

#### Services

In Kubernetes, you can assign arbitrary key-value pairs called labels to any Kubernetes resource. Kubernetes uses labels to group multiple related Pods into a logical unit called a Service. A Service has a stable IP address and ports, and provides load balancing among the set of Pods whose labels match all the labels you define in the label selector when you create the Service.

![](https://cloud.google.com/kubernetes-engine/images/networking-overview_two-services.png)

### Networking outside the cluster

* **External load balancers** manage traffic coming from outside the cluster and outside your Google Cloud VPC network. They use forwarding rules associated with the Google Cloud network to route traffic to a Kubernetes node.
* **Internal load balancers** manage traffic coming from within the same VPC network. Like external load balancers, they use forwarding rules associated with the Google Cloud network to route traffic to a Kubernetes node.
* **HTTP(S) Load Balancers** are specialized external load balancers used for HTTP(S) traffic. They use an Ingress resource rather than a forwarding rule to route traffic to a Kubernetes node.

## [Istio](https://cloud.google.com/istio/docs/istio-on-gke/overview)

* Open service mesh that provides a uniform way to connect, manage, and secure microservices
* Managing traffic flows between services, enforcing access policies, and aggregating telemetry data
* Benefits:
    - Fine-grained control of traffic behavior
    - A configurable policy layer and API that supports access controls, rate limits, and quotas
    - Automatic metrics, logs, and traces for all traffic within a cluster, including cluster ingress and egress.
    - Secure service-to-service communication in a cluster with strong identity-based authentication and authorization.

## [Anthos](https://cloud.google.com/anthos/docs/concepts/overview)

* Application management platform providing consistent development and operations experience for cloud and on-premises environments.

### Computing Environment

* Kubernetes has two main parts: the control plane and the node components. How the environments host the control plane and node components for GKE is described below.

    * **Anthos on Google Cloud**
    
        With Anthos on Google Cloud, Google Cloud hosts the control plane, and the Kubernetes API server is the only control-plane component accessible to customers. GKE manages the node components in the customer's project using instances in Compute Engine.

    * **Anthos on-prem**

        With Anthos clusters on VMware, all components are hosted in the customer's on-prem virtualization environment.

    * **Anthos on AWS**
    
        With Anthos clusters on AWS, all components are hosted in the customer's AWS environment.


# Cloud Functions
* Scalable pay-as-you-go functions as a service (FaaS) to run your code without server management


# Cloud Run
* Develop and deploy highly scalable containerized applications on a fully managed serverless platform.
* Any language, any library, any binary
* No infrastructure to manage
* Scales up or down from zero to N depending on traffic
* Services are regional, automatically replicated across multiple zones
* Mount secrets from Secret Manager.
* Expose publicily to receive web requests
