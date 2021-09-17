provider "google" {
  project = var.project_id
  region  = "uc-central1"
}

// CREATE VPCS
// Create a private VPC
resource "google_compute_network" "private" {
  name                    = "private-network"
  auto_create_subnetworks = false
}

// Create a public VPC
resource "google_compute_network" "public" {
  name                    = "public-network"
  auto_create_subnetworks = false
}

//CREATE SUBNETWORKS
// Create a subnetwork in the private VPC
resource "google_compute_subnetwork" "subnet0" {
  name          = "subnet0"
  ip_cidr_range = "10.128.0.0/16"
  region        = "us-central1"
  network       = google_compute_network.private.id
}
// Create a subnetwork in the public VPC
resource "google_compute_subnetwork" "subnet1" {
  name          = "subnet1"
  ip_cidr_range = "10.129.0.0/16"
  region        = "us-central1"
  network       = google_compute_network.public.id
}

// STATIC ROUTE
// Direct default routes to central firewall
resource "google_compute_route" "private-default-route" {
  name              = "private-to-firewall-default-route"
  dest_range        = "0.0.0.0/0"
  network           = google_compute_network.private.name
  next_hop_instance = google_compute_instance.pfsense-01.id
  priority          = "100"
}