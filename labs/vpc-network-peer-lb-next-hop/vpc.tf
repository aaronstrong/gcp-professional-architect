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
  region        = var.region
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
  region        = var.region
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
  region        = var.region
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
  region        = var.region
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