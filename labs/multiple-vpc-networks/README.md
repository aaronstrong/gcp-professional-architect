# Multiple VPC with Centralized appliance

## Overview

In this lab you create several VPC networks and VM instances and test connectivity across networks. Specifically, you create two custom mode networks (management-networknet and private-network) with firewall rules and VM instances as shown in this network diagram:

![](https://cloud.google.com/vpc/images/multinic/multinic1.svg)

### Objectives

In this lab, you will learn how to perform the following tasks:

* Create custom mode VPC networks with firewall rules
* Create VM instances using Compute Engine
* Explore the connectivity for VM instances across VPC networks
* Create a VM instance with multiple network interfaces

#### Create custom mode VPC networks with firewall rules

**VPC**
```bash
# Public VPC
gcloud compute networks create public-network \
--bgp-routing-mode=global \
--subnet-mode=custom

# management-network VPC
gcloud compute networks create management-network \
--bgp-routing-mode=global \
--subnet-mode=custom

# Private VPC
gcloud compute networks create private-network \
--bgp-routing-mode=global \
--subnet-mode=custom
```
**Subnetwork**
```bash
gcloud compute networks subnets create subnet1 \
--network=public-network \
--region=us-central1 \
--range=10.128.0.0/20

gcloud compute networks subnets create subnet2 \
--network=management-network \
--region=us-central1 \
--range=10.130.0.0/20

gcloud compute networks subnets create subnet0 \
--network=private-network \
--region=us-central1 \
--range=172.16.0.0/24
```

**Firewall**
```bash
# Create rule for IAP for private, public, management VPC
gcloud compute firewall-rules create allow-iap \
--direction=INGRESS \
--priority=1000 \
--network=management-network \
--action=ALLOW \
--rules=tcp:22 \
--source-ranges=35.235.240.0/20

gcloud compute firewall-rules create allow-iap-priv \
--direction=INGRESS \
--priority=1000 \
--network=private-network \
--action=ALLOW \
--rules=tcp:22 \
--source-ranges=35.235.240.0/20

gcloud compute firewall-rules create allow-iap-public \
--direction=INGRESS \
--priority=1000 \
--network=public-network \
--action=ALLOW \
--rules=tcp:22 \
--source-ranges=35.235.240.0/20

# Create rule for inbound traffic for port 3128
gcloud compute firewall-rules create allow-squid-inbound \
--direction=INGRESS \
--priority=1000 \
--network=private-network \
--action=ALLOW \
--rules=tcp:3128 \
--source-ranges=172.16.0.0/24

# Allow Pings in the Private Network
gcloud compute firewall-rules create allow-icmp-private-net \
--direction=INGRESS \
--priority=1000 \
--network=private-network \
--action=ALLOW \
--rules=icmp \
--source-ranges=172.16.0.0/24
```

**Instances**
```bash
# Instance 1
gcloud compute instances create public-network-us-vm-1 \
--network-interface subnet=subnet1,no-address \
--zone=us-central1-b \
--machine-type=g1-small \
--preemptible --no-restart-on-failure \
--maintenance-policy=terminate \
--image-project=ubuntu-os-cloud \
--image=ubuntu-2004-focal-v20210825 \
--boot-disk-size=10GB \
--network-tier=standard

# Instance 2 - with proxy config
gcloud compute instances create private-network-us-vm-1 \
--network-interface subnet=subnet0,no-address \
--zone=us-central1-b \
--machine-type=g1-small \
--preemptible --no-restart-on-failure \
--maintenance-policy=terminate \
--image-project=ubuntu-os-cloud \
--image=ubuntu-2004-focal-v20210825 \
--boot-disk-size=10GB \
--network-tier=standard \
--metadata=startup-script=export\ http_proxy=http://172.16.0.4:3128$'\n'export\ https_proxy=https://172.16.0.4:3128$'\n'curl\ www.google.com --no-restart-on-failure --maintenance-policy=TERMINATE

# Instance 2 - without proxy config
gcloud compute instances create private-network-us-vm-1 \
--subnet=subnet0 --no-address \
--zone=us-central1-b \
--machine-type=g1-small \
--preemptible --no-restart-on-failure \
--maintenance-policy=terminate \
--image-project=ubuntu-os-cloud \
--image=ubuntu-2004-focal-v20210825 \
--boot-disk-size=10GB \
--network-tier=standard
```

**Instace 4 - multiple nics**

[Use the Google Case study to create a Squid Proxy](https://cloud.google.com/vpc/docs/special-configurations)
```bash
# temp assign ephemeral external IP to get squid
gcloud compute instances create vm-appliance \
--zone=us-central1-b \
--network-interface subnet=subnet0 \
--network-interface subnet=subnet2,no-address \
--network-interface subnet=subnet1 \
--machine-type n1-standard-4 \
--preemptible \
--metadata=startup-script=\#\!\ /bin/bash$'\n'sudo\ apt-get\ update$'\n'sudo\ apt-get\ install\ -y\ squid$'\n'$'\n'sudo\ sed\ -i\ \'s:\#\\\(http_access\ allow\ localnet\\\):\\1:\'\ /etc/squid/squid.conf$'\n'sudo\ sed\ -i\ \'s:\#\\\(http_access\ deny\ to_localhost\\\):\\1:\'\ /etc/squid/squid.conf$'\n'sudo\ sed\ -i\ \'s:\#\\\(acl\ localnet\ src\ 10.0.0.0/8.\*\\\):\\1:\'\ /etc/squid/squid.conf$'\n'sudo\ sed\ -i\ \'s:\#\\\(acl\ localnet\ src\ 172.16.0.0/12.\*\\\):\\1:\'\ /etc/squid/squid.conf$'\n'sudo\ sed\ -i\ \'s:\#\\\(acl\ localnet\ src\ 192.168.0.0/16.\*\\\):\\1:\'\ /etc/squid/squid.conf$'\n'sudo\ service\ squid\ start --no-restart-on-failure \
--maintenance-policy=TERMINATE \
--image=debian-10-buster-v20210122 \
--image-project=debian-cloud \
--boot-disk-size=10GB \
--boot-disk-type=pd-standard \
--boot-disk-device-name=gateway-1 \
--no-shielded-secure-boot \
--shielded-vtpm \
--shielded-integrity-monitoring \
--reservation-affinity=any
```

This command creates an instances with three network interfaces:
* `nic0` is attached to subnet0 and has no external IP address
* `nic1` is attached to subnet1 and has an ephemeral external IP address
* `nic2` is attached to sunbet2 and has no external IP address


## Cleanup

**Instances Cleanup**
```bash
gcloud compute instances delete private-network-us-vm-1  --zone=us-central1-b --quiet
gcloud compute instances delete public-network-us-vm --zone=us-central1-b --quiet
gcloud compute instances delete vm-appliance --zone=us-central1-b --quiet
```
**Firewall Cleanup**
```bash

```
**Subnetwork Cleanup**
```bash
gcloud compute networks subnets delete subnet1 --region=us-central1 --quiet
gcloud compute networks subnets delete subnet2 --region=us-central1 --quiet
gcloud compute networks subnets delete subnet0 --region=us-central1 --quiet
```

**VPC Cleanup**
```bash
gcloud compute networks delete public-network --quiet
gcloud compute networks delete management-network --quiet
gcloud compute networks delete private-network --quiet
```

## Terraform

Copy the script below and run
* `terraform init` to initalise
* `terraform plan` to confirm the desired out come
* `terraform apply` with confirmation to deploy the desired state
>Note: [Enable IAP](./iap.md) on the project to access the private instances


```terraform
// Create 3 custom VPC's
resource "google_compute_network" "private" {
    name = "private-network"
    auto_create_subnetworks = false
}

resource "google_compute_network" "management" {
    name = "management-network"
    auto_create_subnetworks = false
}

resource "google_compute_network" "public" {
    name = "public-network"
    auto_create_subnetworks = false
}

// Create a Subnetwork in each VPC
resource "google_compute_subnetwork" "subnet0" {
    name = "subnet0"
    ip_cidr_range = "10.128.0.0/16"
    region = "us-central1"
    network = google_compute_network.private.id
}

resource "google_compute_subnetwork" "subnet1" {
    name = "subnet1"
    ip_cidr_range = "10.129.0.0/16"
    region = "us-central1"
    network = google_compute_network.public.id
}
resource "google_compute_subnetwork" "subnet2" {
    name = "subnet2"
    ip_cidr_range = "10.130.0.0/16"
    region = "us-central1"
    network = google_compute_network.management.id
}

// Create 2 test VM instances
# Deploy 1 instance in the private VPC
resource "google_compute_instance" "private-vm" {
    name = "private-vm"
    machine_type = "g1-small"
    zone = "us-central1-b"

    boot_disk {
        initialize_params {
            image = "ubuntu-os-pro-cloud/ubuntu-pro-2004-lts"
        }
    }

    network_interface {
        network = google_compute_network.private.id
        subnetwork = google_compute_subnetwork.subnet0.id
        access_config {

        }
    }
    scheduling {
        preemptible = true
        automatic_restart = false        
    }
}

# Deploy 1 VM instance in the public VPC
resource "google_compute_instance" "public-vm" {
    name = "public-vm"
    machine_type = "n1-standard-2"
    zone = "us-central1-b"

    boot_disk {
        initialize_params {
            image = "ubuntu-os-pro-cloud/ubuntu-pro-2004-lts"
        }
    }

    network_interface {
        network = google_compute_network.public.id
        subnetwork = google_compute_subnetwork.subnet1.id
        # access_config {}
    }
    scheduling {
        preemptible = true
        automatic_restart = false        
    }
}

// Create Web proxy with 3 NICs
# Create a centralized `HUB`
resource "google_compute_instance" "proxy-vm" {
    name = "hub-proxy"
    machine_type = "n1-standard-4"
    zone = "us-central1-b"

    boot_disk {
        initialize_params {
            image = "ubuntu-os-pro-cloud/ubuntu-pro-2004-lts"
        }
    }

    network_interface {
        network = google_compute_network.public.id
        subnetwork = google_compute_subnetwork.subnet1.id
        access_config {}
    }
    network_interface {
        network = google_compute_network.private.id
        subnetwork = google_compute_subnetwork.subnet0.id
    }
    network_interface {
        network = google_compute_network.management.id
        subnetwork = google_compute_subnetwork.subnet2.id
    }
    scheduling {
        preemptible = true
        automatic_restart = false        
    }

    metadata_startup_script = <<SCRIPT
#! /bin/bash
sudo apt-get update
sudo apt-get install -y squid
sudo sed -i 's:#\(http_access allow localnet\):\1:' /etc/squid/squid.conf
sudo sed -i 's:#\(http_access deny to_localhost\):\1:' /etc/squid/squid.conf
sudo sed -i 's:#\(acl localnet src 10.0.0.0/8.*\):\1:' /etc/squid/squid.conf
sudo sed -i 's:#\(acl localnet src 172.16.0.0/12.*\):\1:' /etc/squid/squid.conf
sudo sed -i 's:#\(acl localnet src 192.168.0.0/16.*\):\1:' /etc/squid/squid.conf
sudo service squid start
SCRIPT
}
```


```terrform
// Create Firewall Rules to allow traffic to hit the `hub-proxy`
# Rules for private network for the hub-proxy
resource "google_compute_firewall" "private-proxy" {
    name = "hub-proxy-private"
    network = google_compute_network.private.name

    allow {
        protocol = "icmp"
    }

    allow {
        protocol = "tcp"
        ports = ["3128"]
    }
}
# Rule to allow IAP into the private VPC
resource "google_compute_firewall" "allow-iap-private-network" {
    name = "allow-iap-private-network"
    network = google_compute_network.private.name
    direction = "INGRESS"
    source_ranges = ["35.235.240.0/20"]
    allow {
        protocol = "tcp"
        ports = ["22"]
    }
}

# Rules for public network for the hub-proxy
resource "google_compute_firewall" "public-proxy" {
    name = "hub-proxy-public"
    network = google_compute_network.public.name

    allow {
        protocol = "icmp"
    }

    allow {
        protocol = "tcp"
        ports = ["3128"]
    }
}

# Rule to allow IAP into the public VPC
resource "google_compute_firewall" "allow-iap-public-network" {
    name = "allow-iap-public-network"
    network = google_compute_network.public.name
    direction = "INGRESS"
    source_ranges = ["35.235.240.0/20"]
    allow {
        protocol = "tcp"
        ports = ["22"]
    }
}
```


## Client Setup

* SSH into one of the client instances, <u>**not**</u> the hub-proxy. You should be successful in pinging the `hub-proxy`.
* Update the instance to use the hub-proxy for outbound connection.
>Note: Update the IP address to that of the hub-proxy
```bash
export http_proxy=http://10.129.0.6:3128
export https_proxy=https://10.129.0.6:3128
curl www.google.com
```

## Cleanup

Run a `terraform destroy` to remove everything that was deployed.