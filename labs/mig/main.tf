# -------------------------------------------------------------------
# PROVIDER
# https://medium.com/google-cloud/squid-proxy-cluster-with-ssl-bump-on-google-cloud-7871ee257c27
# https://cloudinfrastructureservices.co.uk/how-to-setup-squid-proxy-server-on-google-gcp/
# -------------------------------------------------------------------

provider "google" {
  project = var.project_id
  credentials = var.gcp_credentials
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  credentials = var.gcp_credentials
  region  = var.region
}

# -------------------------------------------------------------------
# VPC
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
  region        = var.region
  network       = google_compute_network.hub.id
}

# -------------------------------------------------------------------
# FIREWALL RULES
# -------------------------------------------------------------------
// Rule to allow IAP into the private VPC
resource "google_compute_firewall" "allow-iap-private-network" {
  name          = "allow-iap-private-network"
  network       = google_compute_network.hub.name
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]
  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }
}

// All internal ICMP
resource "google_compute_firewall" "allow-internal-vpc" {
  name          = "allow-internal-vpc"
  network       = google_compute_network.hub.name
  direction     = "INGRESS"
  source_ranges = ["10.0.0.0/24"]

  allow {
    protocol = "icmp"
  }
}

// Deny Egress HTTP(S) ports
resource "google_compute_firewall" "deny-web-outbound" {
  name      = "deny-web-egress"
  network   = google_compute_network.hub.name
  direction = "EGRESS"
  priority  = "1100"

  deny {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}

# -------------------------------------------------------------------
# INSTANCES
# -------------------------------------------------------------------
# Deploy a test instance in the private VPC
# without a public IP address
resource "google_compute_instance" "private-vm" {
  count        = var.testvm_count
  name         = "private-vm-${var.testvm_count}"
  machine_type = "g1-small"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  network_interface {
    network    = google_compute_network.hub.id
    subnetwork = google_compute_subnetwork.subnet0.id
  }

  scheduling {
    preemptible       = true
    automatic_restart = false
  }
}