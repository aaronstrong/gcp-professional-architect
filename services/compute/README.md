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

## App Engine


## Google Kubernetes Engine (GKE)
