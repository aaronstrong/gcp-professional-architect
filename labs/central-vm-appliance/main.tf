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

# -------------------------------------------------------------------
# FIREWALL RULES
# GCP by default has a deny ingress rule. To allow traffic, you must
# create exceptions
# -------------------------------------------------------------------
// Rule to allow IAP into the hub VPC
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

# HUB VPC firewall rule
// Allow ingress into the untrust VPC
// (Best practice would be to NOT allow ALL traffic from any source and any protocol)
resource "google_compute_firewall" "allow-ingress-public-vpc" {
  name          = "allow-ingress-public-vpc"
  network       = google_compute_network.hub.name
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]

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
    network    = google_compute_network.hub.id
    subnetwork = google_compute_subnetwork.subnet0.id
    access_config {}
    // reserve an internal static ip
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
    network    = google_compute_network.hub.id
    subnetwork = google_compute_subnetwork.subnet0.id
    access_config {}
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
    network    = google_compute_network.hub.id
    subnetwork = google_compute_subnetwork.subnet0.id
  }

  scheduling {
    preemptible       = true
    automatic_restart = false
  }
}