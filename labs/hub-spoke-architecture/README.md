# Hub-and-Spoke Achitecture with Network Virtual Appliances (NVA)

![](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/raw/master/fast/stages/2-networking-c-nva/diagram.svg)


### VPC Peering

<u>[Limits](https://cloud.google.com/vpc/docs/vpc-peering#specifications)</u>
* Not transitive
* On-premises resources will not be able to route to Google Managed Services (IE: Cloud SQL, VMware Engine, GKE Control Plane) In the VPC-peered projects. VPC Peering does
* Resources in the `prod-net-spoke-0` project will not be able to communicate with resources in the `dev-net-spoke-0` project. Either use a Cloud VPN or a VPC Peer between the projects.
* VPC Peering is limited to 25 peers per VPC.
* Policy-based routes are never exchanged through peering

<u>Positives</u>
* No limits on the network speed. High throughput, low latency
* VPC Peering does not exchanage VPC firewall rules


### Trusted VPC
<u>Notes</u>
* [Custom static routes](./nva.tf#L179) are created in the Trusted VPC and through the VPC peering are exported to other peered projects. 
* [Firewall rules to allow ICMP](vpc.tf#L35) have been configured. This configuration allows VMs from spoke projects to use `ping` to validate connectivity to the `Trusted VPC` and `Untrusted VPC`.


**Note**: Cloud Router for the Cloud VPN <i>MUST</i> be configured to use [custom route advertisement](https://cloud.google.com/network-connectivity/docs/router/concepts/overview#route-advertisement-custom).



----

