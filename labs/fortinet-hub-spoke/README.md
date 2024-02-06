# FortiGate Terraform Module

This repo contains terraform modules to deploy and manage FortiGate reference architecture in Google Cloud. It uses both Google Cloud as well as FortiOS providers to demonstrate high agility of managing FortiGate appliances together with cloud using IaC approach.

## Architecture

![](https://cloud.google.com/static/architecture/images/partners/fortigate-provisioning-architecture.svg)

**Resources**
- 1 - Bucket to upload the FortiGate image
- 2 - VPCs
- 1 subnet in each VPC in the same region
- 1 - GCE instance loaded with the FortiGate software
- 2 - vNICs attached to the FortiGate instance
- 1 - Zonal unmanaged instance group
- 1 - Internal Load Balancer



## Base Module

This configuration deploys a single FortiGate appliance into GCP and connects it to two subnets. We are deploying an evaulation licensed FortiGate, and the license only works on an instance that's sized with 1 vCPU and 2GB of RAM (`custom-1-2018`). Two VPCs and a subnet in each are created. 

The design is using a "load balancer sandwich" design with ILBs (Internal Load Balancers) used as a custom route next-hop for detecting currently active instance and routing traffic through it. Base configuration include the ILB on the trusted side of the VPC.

More details on the design can be found [here](./architecture-reference.md).

### Licenses

This tutorial uses the EVALUATION-licensed images. You must obtain and activate your licenses before running the terraform configuration.

More details on this process can be found [here](./EVALCOPY.md)

## How to deploy
1. deploy the code by running `terraform init`, `terraform apply`
1. Setup the firewall by hand manually:
    1. MANUAL: Use the public ip address and login with the out of the box configure of <admin> and <password>. The password is the instance id.
    1. Use your login information from FortiNet.
    1. Reboot the firewall.
    1. Once back up, login and run through the wizards.
    1. After at the Dashboard Status, open up the Cloud Shell prompt and paste in the auto-generate `my-config.yaml` file.
    1. Validate the Internal Load Balancer is marked `UP`.
1. Proceed with configuring the firewall rules

After everything is deployed you can connect to the management NIC of primary FortiGate using SSH or HTTPS (on standard ports) via the first IP address printed in `fgt-mgmt-eips`. Log in as **admin**, the initial password is set to primary instance id (for convenience visible as `default_password` output).



## References
- [Cloud DNS Best Practices - Hybrid](https://cloud.google.com/dns/docs/best-practices#reference_architectures_for_hybrid_dns)
- [Cloud DNS Private Zones](https://cloud.google.com/dns/docs/zones/zones-overview#ptr_records_in_private_zones)
- [Configure active directory zone forwarding - Win2016](https://www.readandexecute.com/how-to/server-2016/dns/configure-dns-forwarders-windows-server-2016/)
- [Manage DNS Zones using DNS server in Windows Server](https://learn.microsoft.com/en-us/windows-server/networking/dns/manage-dns-zones?tabs=powershell)
- [GCP Internal Load Balancer Next Hop Overview](https://cloud.google.com/load-balancing/docs/internal/ilb-next-hop-overview)