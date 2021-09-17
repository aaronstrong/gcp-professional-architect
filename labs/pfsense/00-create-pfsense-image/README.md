# Steps to create a pfSense image in Google Cloud Platform
The steps below were performed on a windows 10 machine running WSL 2.0. Most of the sources on the Internet for converting the pfSense image were done on a MacOS.

## Prerequirements
* Some working knowledge of Google Cloud Platform
* Google SDK
* Windows 10 with WSL or a Linux distro

## Steps
1. Download pfSense
    1. You can manually [download by going here](https://www.pfsense.org/download/).
    1. From a Linux or WSL machine
        ```bash
        wget https://nyifiles.netgate.com/mirror/downloads/pfSense-CE-memstick-serial-2.5.2-RELEASE-amd64.img.gz
        ```
1. Decompress the downloaded `*.gz` file
    1. From a Linux or WSL machine
        ```bash
        gunzip pfSense-CE-memstick-serial-2.5.2-RELEASE-amd64.img.gz
        ```
        This will create a new file that ends with `*.img`
1. Convert to a `*.raw` file
    1. Create a new `*.raw` image file using the dd commands below from a Linux or WSL terminal
        ```bash
        dd if=pfSense-CE-memstick-serial-2.4.4-RELEASE-amd64.img of=disk.raw bs=4m conv=sparse
        ```
        > Note: I got an error message and ran this modified command instead:<br>`dd if=pfSense-CE-memstick-serial-2.4.4-RELEASE-amd64.img of=disk.raw bs=4M conv=sparse`
1. Convert the `*.raw` file into a `tar.gz` file
    1. For this step I first needed to download the tar application on my WSL machine.
        ```bash
        sudo apt-get update -y
        sudo apt-get install -y tar
        ```
    1. Convert the `*.raw` file into a `tar.gz` file
        - `tar -Sczf pfSense-CE-memstick-serial-2.5.2-RELEASE-amd64.img.tar.gz disk.raw`
1. Create a new [GCS bucket](https://cloud.google.com/storage/docs/creating-buckets#storage-create-bucket-gsutil)
    1. Create a new Google Cloud Storage Bucket in your project
        ```bash
        gsutil mb -c nearline -l us-central1 gs://`BUCKET_NAME`
        ```

        * `-p`: Project ID
        * `-c`: Storage Class
        * `-l`: Location
1. Upload the `*.img` file into the bucket
1. Create a new [Custom Image](https://cloud.google.com/compute/docs/images/create-delete-deprecate-private-images#create_image) from the file that was uploaded
    1. We need to create a disk image from the file that was uploaded
        ```bash
        gcloud compute images create pfsense2-5-2 \
            --project=<PROJECT_ID> \
            --source-uri=https://storage.googleapis.com/<BUCKET>/ pfSense-CE-memstick-serial-2.5.2-RELEASE-amd64.img.tar.gz \
            --storage-location=us-central1
        ```
        * `<PROJECT_ID>`: The GCP Project ID these resources are deployed into
        * `<BUCKET>`: Bucket name created in earlier steps

<!-- # Steps to deploy a single NIC pfSense instance
1. Create a VM instance
    1. Create the VM instance from the image file created in previous steps
        ```bash
        gcloud beta compute --project=<PROJECT_ID> instances create pfsense2-5-2 \
            --zone=us-central1-b \
            --machine-type=n1-standard-2 \
            --subnet=<SUBNETWORK> \
            --network-tier=PREMIUM \
            --can-ip-forward \
            --no-restart-on-failure \
            --maintenance-policy=TERMINATE \
            --preemptible \
            --service-account=<PROJECT_NUMBER>-compute@developer.gserviceaccount.com \
            --scopes=https://www.googleapis.com/auth/cloud-platform \
            --tags=https-server \
            --image=pfsense-2-5-2 \
            --image-project=<PROJECT_NUMBER> \
            --boot-disk-size=20GB \
            --boot-disk-type=pd-balanced \
            --boot-disk-device-name=pfsense2-5-2 \
            --reservation-affinity=any
        ```
        * `<PROJECT_ID>`: The GCP Project ID these resources are deployed into
        * `<PROJECT_NUMBER>`: The unique Project Number of the project
        * `<SUBNETWORK>`: If not using a custom VPC, then you can substitute with `default`. See command below to get subnetworks.

            - Command to get project number: `gcloud projects describe <PROJECT_ID>`
            - Command to get subnetworks: `gcloud compute networks subnets list`
        
1. Access the VM through the serial-port
    1. allow access through serial port
        ```bash
        gcloud compute instances add-metadata --project=<PROJECT_ID> --zone=us-central1-b --metadata=serial-port-enable=1 pfsense2-5-2
        ```
1. Install pfSense
1. Customize pfSense
    1. Dislabe pfSense first time login
        - From the serial console:
            - Select Option 8)
            - type `pfSsh.php playback disablereferercheck`
    1. login with default credentials
        - `admin` and `pfsense` are the defaults
    1. Change the default credentials
    >Note: My pfSense web interface at times stops, so I had to use the `pfctl -d` from the console to disable firewall functionality to allow me back. `pfctl -e` to enable
1. Firewall Setup

    * Interfaces > Assignments > Add the vtnet1 interface<br>
    * Interfaces > Assignemtns > LAN (vtnet1) > Enable: true / IPv4 Configuration Type: DHCP / Click Save / Click Apply Changes
        
    * Firewall > NAT > Outbound / Select `Manual Outbound NAT rule generation` > Create a new rule by clicking `Add` > Interface WAN / Protocol:Any / Source: Network with source network (10.128.0.0/16) / Destination: Any / Address: Interface Address / Click `Save` / Click `Apply Changes`<br>
    * Firewall > Rules > LAN > Action: Pass / Interface: LAN / Protocol:Any / Source: Network, 10.128.0.0/16 / Destination: Any / Click `Save` / Click `Apply Changes`


# Steps to deploy a multi-NIC pfSense instance

1. Create multiple VPCs
    ```terraform
    // Creaet 3 custom VPC's
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
    ```
1. Create a subnet in each VPC
    ```terraform
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
    ```
1. [Create the pfSense Image](#Steps-for-deploying-pfSense-in-Google-Cloud-Platform)
1. Deploy the instance with multiple NICs
    ```terraform
    # Deploy 1 VM instance in the public VPC
    resource "google_compute_instance" "pfsense-1" {
        name = "public-vm"
        machine_type = "n1-standard-4"
        zone = "us-central1-b"
        can_ip_forward = true

        boot_disk {
            initialize_params {
                image = "${var.project_id}/pfsense-2-5-2"
                size = 20
                type = "pd-standard"
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

        metadata = {
            #serial-port-logging-enabled = "TRUE"
            serial-port-enable = true
        }
    }

    variable "project_id" {
        description = "The Project ID"
        type = string
    }

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
            # access_config {}
        }
        scheduling {
            preemptible = true
            automatic_restart = false        
        }
    }
    ```
1. Firewal Rules
    ```terraform
    # Allow inbound access to the pfSense
    resource "google_compute_firewall" "pfsense-to-manage" {
        name = "pfsense-allow-mgmt"
        network = google_compute_network.public.name
        allow {
            protocol = "tcp"
            ports = ["443"]
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
    resource "google_compute_firewall" "private-vpc-for-all" {
        name = "private-vpc-for-all"
        network = google_compute_network.private.name

        allow {
            protocol = "icmp"
        }
    }
    ```
1. Setup pfSense
1. Customize pfSense
    - Enable all interfaces and confirm they have IP addresses assigned to them. -->


## Sources

|  |
| -------|
| [Video 1](https://www.youtube.com/watch?v=iOXz3foEPqk&t=7s) |
| [Video 2](https://www.youtube.com/watch?v=pYIo2Kmv2f0) |
| [Serial Port Access](https://cloud.google.com/compute/docs/troubleshooting/troubleshooting-using-serial-console#gcloud) |
| [Create images in Google](https://cloud.google.com/compute/docs/images/create-delete-deprecate-private-images#gcloud) |
| [Create pfSense in GCP](https://silasthomas.medium.com/how-to-import-a-pfsense-firewall-into-google-cloud-platform-ad62257a143a)|
| [pfSense as a BGP endpoint](https://jimangel.io/post/google-cloud-vpn-pfsense/) |
| [pfSense NAT and Port Forward](https://www.youtube.com/watch?v=MMu6BWNXgHA) |
| [Multi-nic video](https://www.youtube.com/watch?v=cMCqZ4nd6ls)|
| [Centralized network appliance on GCP](https://cloud.google.com/architecture/architecture-centralized-network-appliances-on-google-cloud) |
| [Setting up Next Hop with Internal Load Balancer](https://cloud.google.com/load-balancing/docs/internal/setting-up-ilb-next-hop#third_party) |
| [ILB Next Hop Overview](https://cloud.google.com/load-balancing/docs/internal/ilb-next-hop-overview) |
| [ILB Overview](https://cloud.google.com/load-balancing/docs/internal/) |
| [GCP Health Checks](https://cloud.google.com/load-balancing/docs/health-check-concepts) |
