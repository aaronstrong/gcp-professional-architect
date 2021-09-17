# -------------------------------------------------------------------
# PROVIDER
# -------------------------------------------------------------------

provider "google" {
  project = var.project_id
  region  = "uc-central1"
}

# -------------------------------------------------------------------
# VPC
# Create the four VPCs and assign subnet ranges to each.
# -------------------------------------------------------------------
// Create a Hub VPC
resource "google_compute_network" "hub" {
  name                    = "hub-network"
  auto_create_subnetworks = false
}

// Create a subnetwork in the hub VPC
resource "google_compute_subnetwork" "subnet0" {
  name          = "subnet0"
  ip_cidr_range = "10.0.0.0/24"
  region        = "us-central1"
  network       = google_compute_network.hub.id
}

// Create an untrust VPC
resource "google_compute_network" "untrust" {
  name                    = "untrust-network"
  auto_create_subnetworks = false
}

// Create a subnetwork in the untrust VPC
resource "google_compute_subnetwork" "subnet1" {
  name          = "subnet1"
  ip_cidr_range = "10.0.10.0/24"
  region        = "us-central1"
  network       = google_compute_network.untrust.id
}

// Create a transit VPC
resource "google_compute_network" "transit" {
  name                    = "transit-network"
  auto_create_subnetworks = false
}

// Create a subnetwork in the transit VPC
resource "google_compute_subnetwork" "subnet2" {
  name          = "subnet2"
  ip_cidr_range = "10.0.20.0/24"
  region        = "us-central1"
  network       = google_compute_network.transit.id
}

// Create a spoke-a VPC
resource "google_compute_network" "spoke-a" {
  name                            = "spoke-a-network"
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
}

// Create a subnetwork in the spoke a VPC
resource "google_compute_subnetwork" "subnet3" {
  name          = "subnet3"
  ip_cidr_range = "10.131.0.0/16"
  region        = "us-central1"
  network       = google_compute_network.spoke-a.id
}

// Create a VPC peer between the hub vpc and spoke-a vpc
module "peering" {
  source  = "terraform-google-modules/network/google//modules/network-peering"
  version = "3.4.0"

  prefix        = "network-peer"
  local_network = google_compute_network.hub.self_link
  peer_network  = google_compute_network.spoke-a.self_link

  export_local_subnet_routes_with_public_ip = false
  export_local_custom_routes                = true

  module_depends_on = [
    google_compute_network.hub,
    google_compute_network.spoke-a
  ]
}

// STATIC ROUTE
// Direct default routes to central firewall
resource "google_compute_route" "hub-default-route" {
  name         = "route-ilb"
  dest_range   = "0.0.0.0/0"
  network      = google_compute_network.hub.name
  next_hop_ilb = google_compute_forwarding_rule.google_compute_forwarding_rule.id
  priority     = "800"
}


# -------------------------------------------------------------------
# FIREWALL RULES
# GCP by default has a deny ingress rule. To allow traffic, you must
# create exceptions
# -------------------------------------------------------------------
// Rule to allow IAP into the private VPC
resource "google_compute_firewall" "allow-iap-private-network" {
  name          = "allow-iap-private-network"
  network       = google_compute_network.spoke-a.name
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]
  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }
}

# Public VPC firewall rule
// Allow ingress into the untrust VPC
// (Best practice would be to NOT allow ALL traffic from any source and any protocol)
resource "google_compute_firewall" "allow-ingress-public-vpc" {
  name          = "allow-ingress-public-vpc"
  network       = google_compute_network.untrust.name
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "all"
  }
}

// All ingress into spoke-a vpc
resource "google_compute_firewall" "allow-ingress-spoke-a-vpc" {
  name          = "allow-ingress-spoke-a-vpc"
  network       = google_compute_network.spoke-a.name
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "all"
  }
}

// All ingress into hub vpc
resource "google_compute_firewall" "allow-ingress-hub-vpc" {
  name          = "allow-ingress-hub-vpc"
  network       = google_compute_network.hub.name
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "all"
  }
}

// Firewall rule for the GCP Health-check
resource "google_compute_firewall" "default-hc" {
  project = var.project_id
  name    = "firewall-hc"
  network = google_compute_network.hub.name
  allow {
    protocol = "tcp"
    ports    = ["443", "80"]
  }
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
}

// Firewall rule to allow ingress for the hub vpc
resource "google_compute_firewall" "default-ilb-fw" {
  project = var.project_id
  name    = "firewall-ilb-fw"
  network = google_compute_network.hub.name
  allow {
    protocol = "all"
  }
}

# -------------------------------------------------------------------
# INSTANCES
# -------------------------------------------------------------------
# Deploy central Firewall
resource "google_compute_instance" "pfsense-01" {
  name           = "pfsense-vm-01"
  machine_type   = "n1-standard-4"
  zone           = "us-central1-b"
  can_ip_forward = true

  metadata = {
    #serial-port-logging-enabled = "TRUE"
    serial-port-enable = true
  }

  boot_disk {
    initialize_params {
      image = "${var.project_id}/pfsense-2-5-2"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.untrust.id
    subnetwork = google_compute_subnetwork.subnet1.id
    access_config {}
    // reserve an internal static ip
  }
  network_interface {
    network    = google_compute_network.hub.id
    subnetwork = google_compute_subnetwork.subnet0.id
    // reserve an internal static ip
  }
  network_interface {
    network    = google_compute_network.transit.id
    subnetwork = google_compute_subnetwork.subnet2.id
  }

  scheduling {
    preemptible       = true
    automatic_restart = false
  }
}

resource "google_compute_instance" "pfsense-02" {
  name           = "pfsense-vm-02"
  machine_type   = "n1-standard-4"
  zone           = "us-central1-c"
  can_ip_forward = true

  metadata = {
    #serial-port-logging-enabled = "TRUE"
    serial-port-enable = true
  }

  boot_disk {
    initialize_params {
      image = "${var.project_id}/pfsense-2-5-2"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.untrust.id
    subnetwork = google_compute_subnetwork.subnet1.id
    access_config {}
  }
  network_interface {
    network    = google_compute_network.hub.id
    subnetwork = google_compute_subnetwork.subnet0.id
  }
  network_interface {
    network    = google_compute_network.transit.id
    subnetwork = google_compute_subnetwork.subnet2.id
  }

  scheduling {
    preemptible       = true
    automatic_restart = false
  }
}
# Deploy a test instance in the private VPC
# without a public IP address
resource "google_compute_instance" "private-vm" {
  name         = "private-vm"
  machine_type = "g1-small"
  zone         = "us-central1-b"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-pro-cloud/ubuntu-pro-2004-lts"
    }
  }

  network_interface {
    network    = google_compute_network.spoke-a.id
    subnetwork = google_compute_subnetwork.subnet3.id
  }

  scheduling {
    preemptible       = true
    automatic_restart = false
  }
}

# -------------------------------------------------------------------
# UNMANAGED INSTANCE GROUPS
#
# These firewalls are stateful and to prevent asymmetric routing,
# traffic needs to be sent to one firewall at a time. Two firewalls
# will be deployed, but one will be placed in an instance group marked
# for failover purpose only.
# -------------------------------------------------------------------
// Create two instance groups (IG) and put a stateful firewall in each IG
// Instance Group 1
resource "google_compute_instance_group" "fw-umig-01" {
  name        = "firewall-umig-01"
  description = "Terraform unmanaged instance groups"
  zone        = "us-central1-b"
  network     = google_compute_network.untrust.id

  instances = [
    google_compute_instance.pfsense-01.id,
  ]
}

// Instance Group 2
resource "google_compute_instance_group" "fw-umig-02" {
  name        = "firewall-umig-02"
  description = "Terraform unmanaged instance groups"
  zone        = "us-central1-c"
  network     = google_compute_network.untrust.id

  instances = [
    google_compute_instance.pfsense-02.id,
  ]
}

// Create the GCP Health Check
resource "google_compute_health_check" "http" {
  name = "health-check-http"

  timeout_sec        = 5
  check_interval_sec = 10

  https_health_check {
    port = "443"
  }
}

// CREATE INTERNAL LOAD BALANCER
# forwarding rule
resource "google_compute_forwarding_rule" "google_compute_forwarding_rule" {
  project               = var.project_id
  name                  = "l4-ilb-forwarding-rule"
  description           = "managed by terraform"
  region                = "us-central1"
  network               = google_compute_network.hub.id
  subnetwork            = google_compute_subnetwork.subnet0.id
  allow_global_access   = false
  backend_service       = google_compute_region_backend_service.umig.self_link
  provider              = google-beta
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL"
  all_ports             = true
}

# region backend
resource "google_compute_region_backend_service" "umig" {
  name                            = "firewall-with--tcp-hc"
  project                         = var.project_id
  provider                        = google-beta
  region                          = "us-central1"
  protocol                        = "TCP"
  load_balancing_scheme           = "INTERNAL"
  network                         = google_compute_network.hub.id
  health_checks                   = [google_compute_health_check.http.id]
  connection_draining_timeout_sec = 300
  backend {
    group       = google_compute_instance_group.fw-umig-01.self_link
    description = "Instance Group 1"
    failover    = false
  }
  backend {
    group       = google_compute_instance_group.fw-umig-02.self_link
    description = "Instance Group 2"
    failover    = true
  }
}
