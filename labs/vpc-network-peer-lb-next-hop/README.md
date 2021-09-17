# Centralized network appliances - VPC Network Peering and internal TCP/UDP load balancer as next hop

![](https://cloud.google.com/architecture/images/arch-centralized-network-8.svg)

## Combining multiple network interfaces and VPC Network Peering with Internal Load Balancer as next hop

This architecture is a typical use case for enterprise environments, using the internal TCP/UDP load balancer for high availability, combined with VPC Network Peering for attaching network segments.

Diagram shows a hub VPC network and multiple spoke VPC networks that are peered with the hub VPC network by using VPC Network Peering. The hub VPC network has 2 instances of a virtual appliance in a managed instance group behind an internal TCP/UDP load balancer. A static default route points to the internal TCP/UDP load balancer as the next hop. This static default route is exported over the VPC Network Peering by using custom routes. The default route to the internet gateway in the spoke VPC networks is deleted.

## Before You Begin

The terraform code in the repository mimics the diagram very closely. A pair of multi-nic [pfSense firewalls](https://www.pfsense.org/) were chosen because of the stateful nature of firewalls and the complexities of getting instances to route through a pair of centalized firewalls in GCP.

## Requirements

* A pfSense image has been created in Google Cloud. If not, [follow this guide](../pfsense/create-pfsense-image).
* [pfSense has been installed](../pfsense/pfsense-install).

### What's Deployed

* Four VPCs with a subnet in each
* 2 of those VPCs will be peered together
* An internal load balancer with backend instance groups
* Multiple firewall rules
* A pair of pfSense firewalls
* A single test VM instance deployed in the `Spoke-A` VPC

### How to deploy

* `terraform init`
* `terraform plan`
* `terraform apply`

## pfSense configuration

After the `terraform` code has been ran and completed successfully, configure each pfsense instance individually.

1. Navigate to the Compute Engine console.
1. Select `pfsense-vm-01` and click the `Connect to serial console`.
1. Follow the pfsense install guide.
1. Repeat the steps for the second pfsense vm instance.

### Additional pfsense configuration for a multi-nic configure and load balancer config

There's some additional configuration, specifically routing, that needs to be configure for each pfsense VM instance.

### Setup the LAN interface that connects to the Hub VPC

Follow these steps:

1. From the top menu: Interfaces > Assignments 
    * Select `vtnet1` from the dropdown
    * Click Add > Click Save
1. From the top menu: Interfaces > LAN
    * Enable: Check `Enable interface`
    * IPv4 Configuration Type: Select Static IPv4
    * Under Static IPv4 Configuration / IPv4 Address / `10.0.0.2/24`
    * Click Save > Click Apply
    >:notebook: May need to restart the instance from the serial console after this change.

### Add a LAN Gateway and Static Routes

1. From the top menu: System > Routing > Add
    * Interface: LAN
    * Name: LAN_GATEWAY
    * Gateway: `10.0.0.1`
        >:notebook: This will be the default gateway IP of the VPC
    * Click Save / Click Apply
1. System > Routing > Static Routes > Add
    * `Spoke-A Network`
        * Destination network: `10.131.0.0` / subnetmask: `16`
        * Gateway: LAN_GATEWAY
        * Click Save
    * `transit Network`
        * Destination network: `10.0.20.0` / subnetmask: `24`
        * Gateway: LAN_GATEWAY
        * Click Save
    * `Google HealthCheck Network 1`
        * Destination network: `130.211.0.0` / subnetmask: `22`
        * Gateway: LAN_GATEWAY
        * Click Save
    * `Google HealthCheck Network 2`
        * Destination network: `35.191.0.0` / subnetmask: `16`
        * Gateway: LAN_GATEWAY
        * Click Save
1. Click Apply Changes

### Create a Catch All Alias

Creating an alias will allow us to lump in some of the networks under one alias to simplify the firewall rules later.

1. From the top menu: Firewall > Aliases > IP
    * Click Add > Name it `Catch_All`
    * Type: Networks
    * Add the three networks:
        1. 10.0.0.0/8
        1. 35.191.0.0/16
        1. 130.211.0.0/22
    * Click Save / Click Apply

### Create a 1:1 NAT rule

Without this 1:1 mapping, the GCP Health checks will fail.

1. Firewall > NAT > 1:1 > Click Add
    * Interface: LAN
    * Address Family: IPv4
    * External subnet IP: Single host / `10.0.0.4` <-- GCP internal Load balancer IP
        > :notebook: The external subnet ip will be the GCP internal load balancer IP. What's shown here now, may not be the same when you deploy it.
    * Internal IP: Single host / `10.0.0.3` <-- Instance IP
    * Click Save / Click Apply

### Create Firewall rules and NAT in pfsense

1. Firewall > NAT > Outbound
    * Select `Hybrid Outbound NAT rule generation.`
        * Click Save
    * Under Mappings > Click Add
        * Interface: LAN
        * Protocol: any
        * Source: any
        * Destination: any
    * Under Mappings > Click Add
        * Interface: WAN
        * Protocol: any
        * Source: any
        * Destination: any

1. Firewall > Rules > LAN > Click Add
    * Interface: LAN
    * Address Family: IPv4
    * Protocol: Any
    * Source: Single host or Alias / `Catch_All`
    * Destination: any
    * Click Save
1. Firewall > Rules > WAN > Click Add
    * Source: Single host or IP / `Your Public IP address`
        >:notebook: Google "what is my ip"
    * Destination Port Range: HTTPS
    * Click Save
    * Apply Changes

Repeat steps for the second firewall

## Clean up

* `terraform destroy`