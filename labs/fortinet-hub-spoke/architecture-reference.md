# FortiGate Reference Architecture for GCP

Reference Architecture features the following build block:

1. A single instance of FortiGate with an ILB next hop.
1. Health Probes from Google

![](https://github.com/fortinet/fortigate-tutorial-gcp/raw/main/docs/images/detail-reference-full.svg)

## VM Instance and Networks

FortiGate is deployed as 1 VM instances in 1 availability zone with 2 NICs each:

* port 1 (nic0) external (untrusted) traffic
* port 2 (nic1) internal (trusted) traffic

[!NOTE]
The number of virtual network interfaces scales with the number of vCPUS with a minimum of 2 and a maximum of 8. If more network interfaces are required, the instance size must change and the FortiGate license with it.

Outbound connections from port1 to Google Compute API and FortiGuard services must be made available, preferably using Cloud NAT or using public IPs attached directly to port1 of each VM.

### Load Balancers and traffic flows

Cloud infrastructure directs traffic flows to the active FortiGate instance using load balancers. In this case load balancers will not really balance the connections but simply direct them to the single active (healthy) instance. Both Internal and External Load Balancers in GCP can use a Backend Service as the target.

Internal Load Balancers will be used as next hop by custom routes and it's enough to use a single rule for any port of either TCP or UDP protocol. Custom route will automatically enable routing of all TCP/UDP/ICMP traffic on all ports.

External Load Balancer does not support routing, so the connections to its public IP addresses will have to be terminated or redirected (DNATed) on the active FortiGate. It's recommended to use the new L3_DEFAULT protocol for ELB.
