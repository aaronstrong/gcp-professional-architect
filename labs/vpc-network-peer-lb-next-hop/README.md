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
        * Destination network: `10.0.5.0` / subnetmask: `24`
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

## Restore from backup

If you don't want to manually configure each pfSense firewall, there are two config files that can be used to restore the mentioned configuration.

* `test-pfsense-us-central1-0` - [10.0.0.2-config.xml](./config/10.0.0.2-config.xml)
* `test-pfsense-us-central1-1` - [10.0.0.3-config.xml](./config/10.0.0.3-config.xml)

## Clean up

* `terraform destroy`

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | 3.90.1 |
| <a name="provider_google-beta"></a> [google-beta](#provider\_google-beta) | 4.5.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_peering"></a> [peering](#module\_peering) | terraform-google-modules/network/google//modules/network-peering | 3.4.0 
|

## Resources

| Name | Type |
|------|------|
| [google-beta_google_compute_forwarding_rule.google_compute_forwarding_rule](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_compute_forwarding_rule) | resource |
| [google-beta_google_compute_region_backend_service.umig](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_compute_region_backend_service) | resource |
| [google_compute_firewall.allow-iap-private-network](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.allow-ingress-hub-vpc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.allow-ingress-public-vpc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.allow-ingress-spoke-a-vpc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.default-hc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.default-ilb-fw](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_health_check.http](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_health_check) | resource |
| [google_compute_instance.pfsense](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) | 
resource |
| [google_compute_instance.private-vm](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) | resource |
| [google_compute_instance_group.fw_umig](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_group) | resource |
| [google_compute_network.hub](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_network.spoke-a](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_network.transit](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_network.untrust](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_route.hub-default-route](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_route) | resource |
| [google_compute_subnetwork.subnet0](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_compute_subnetwork.subnet1](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_compute_subnetwork.subnet2](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_compute_subnetwork.subnet3](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_compute_zones.available](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_zones) | data source |
| [google_netblock_ip_ranges.health_checkers](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/netblock_ip_ranges) | data source |
| [google_netblock_ip_ranges.iap_forwarders](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/netblock_ip_ranges) | data source |
| [google_netblock_ip_ranges.legacy_health_checkers](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/netblock_ip_ranges) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cidr_prefix"></a> [cidr\_prefix](#input\_cidr\_prefix) | Must be given in CIDR notation. The assigned supernet. | `string` | `"10.0.0.0/15"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment | `string` | `"test"` | no |
| <a name="input_firewalls_count"></a> [firewalls\_count](#input\_firewalls\_count) | The total number of firewalls to deploy. | `number` | `2` | no |
| <a name="input_instances_count"></a> [instances\_count](#input\_instances\_count) | The total number of instances to deploy. | `number` | `1` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The Project ID | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region to deploy resources. | `string` | `"us-central1"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->