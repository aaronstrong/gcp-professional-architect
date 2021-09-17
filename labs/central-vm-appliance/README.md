# Centralized Virtualized Network Appliance

![](https://cloud.google.com/architecture/images/arch-centralized-network-1.svg)

The preceding diagram shows the communication paths between segmented VPC networks, on-premises networks, and the internet, and how they are routed through the centralized, virtualized network appliance.

## Requirements

A pfSense image has been created in Google Cloud. If not, [follow this guide](../pfsense/README.MD).

### What's Deployed

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