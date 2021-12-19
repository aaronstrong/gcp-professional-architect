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
  name                    = module.vpc_hub.id
  auto_create_subnetworks = false
}

# -------------------------------------------------------------------
# CREATE SUBNETS
# Create two different subnets and CIDR blocks in different regions
# -------------------------------------------------------------------

resource "google_compute_subnetwork" "subnet0" {
  # Creaet the first subnet in region us-central1
  name = module.vpc_subnet_01.id
  #ip_cidr_range = var.cidr_range_1
  ip_cidr_range = cidrsubnet(var.cidr_prefix, 1, 0)
  region        = var.region
  network       = google_compute_network.hub.id
}

resource "google_compute_subnetwork" "subnet1" {
  # Create the second subnet in region us-east1
  name          = module.vpc_subnet_02.id
  ip_cidr_range = cidrsubnet(var.cidr_prefix, 1, 1)
  region        = "us-east1"
  network       = google_compute_network.hub.id
}