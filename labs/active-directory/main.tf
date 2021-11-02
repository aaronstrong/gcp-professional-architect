# -------------------------------------------------------------------
# PROVIDER
# -------------------------------------------------------------------

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# -------------------------------------------------------------------
# VPC
# Create a VPC
# -------------------------------------------------------------------

resource "google_compute_network" "hub" {
  name                    = "hub-network"
  auto_create_subnetworks = false
}

# -------------------------------------------------------------------
# CREATE SUBNETS
# Create two different subnets and CIDR blocks in different regions
# -------------------------------------------------------------------

resource "google_compute_subnetwork" "subnet0" {
  # Creaet the first subnet in region us-central1
  name          = "subnet0"
  ip_cidr_range = var.cidr_range_1
  region        = "us-central1"
  network       = google_compute_network.hub.id
}

resource "google_compute_subnetwork" "subnet1" {
  # Create the second subnet in region us-east1
  name          = "subnet1"
  ip_cidr_range = var.cidr_range_2
  region        = "us-east1"
  network       = google_compute_network.hub.id
}