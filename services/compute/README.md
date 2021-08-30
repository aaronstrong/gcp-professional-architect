# Google Compute Instances
[Official documentation](https://cloud.google.com/compute/docs/concepts)

Compute Engine instances can run the public images for Linux and Windows Server that Google provides as well as private custom images that you can create or import from your existing systems.

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

## [App Engine](https://cloud.google.com/appengine/docs/flexible/python/an-overview-of-app-engine)

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






## Google Kubernetes Engine (GKE)
