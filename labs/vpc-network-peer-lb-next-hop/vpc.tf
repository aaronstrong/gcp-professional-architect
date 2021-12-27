locals {
  hub_cidr     = cidrsubnet(var.cidr_prefix, 9, 0)
  spokea_cidr  = cidrsubnet(var.cidr_prefix, 9, 5)
  untrust_cidr = cidrsubnet(var.cidr_prefix, 9, 10)
  transit_cidr = cidrsubnet(var.cidr_prefix, 9, 20)

  hub_vpc_name        = "hub-vpc"
  hub_subnet_name     = "${var.environment}-${var.region}-hub-subnet-0"
  untrust_vpc_name    = "untrust-vpc"
  untrust_subnet_name = "${var.environment}-${var.region}-untrust-subnet-0"
  transit_vpc_name    = "transit-vpc"
  transit_subnet_name = "${var.environment}-${var.region}-transit-subnet-0"
  spoke_a_vpc_name    = "spoke-a-vpc"
  spoke_a_subnet_name = "${var.environment}-${var.region}-spoke-a-subnet-0"
}

# -------------------------------------------------------------------
# VPC
# Create the four VPCs and assign subnet ranges to each.
# -------------------------------------------------------------------

resource "google_compute_network" "hub" {
  # Create a Hub VPC
  name                    = local.hub_vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet0" {
  # Create a subnetwork in the hub VPC
  name          = local.hub_subnet_name
  ip_cidr_range = local.hub_cidr
  region        = var.region
  network       = google_compute_network.hub.id
}

resource "google_compute_network" "untrust" {
  # Create an untrust VPC
  name                    = local.untrust_vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet1" {
  # Create a subnetwork in the untrust VPC
  name          = local.untrust_subnet_name
  ip_cidr_range = local.untrust_cidr
  region        = var.region
  network       = google_compute_network.untrust.id
}

resource "google_compute_network" "transit" {
  # Create a transit VPC
  name                    = local.transit_vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet2" {
  # Create a subnetwork in the transit VPC
  name          = local.transit_subnet_name
  ip_cidr_range = local.transit_cidr
  region        = var.region
  network       = google_compute_network.transit.id
}

resource "google_compute_network" "spoke-a" {
  # Create a spoke-a VPC
  name                            = local.spoke_a_vpc_name
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "subnet3" {
  # Create a subnetwork in the spoke a VPC
  name          = local.spoke_a_subnet_name
  ip_cidr_range = local.spokea_cidr
  region        = var.region
  network       = google_compute_network.spoke-a.id
}

module "peering" {
  # Create a VPC peer between the hub vpc and spoke-a vpc
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

resource "google_compute_route" "hub-default-route" {
  # Direct default routes to central firewall
  name         = "route-ilb"
  dest_range   = "0.0.0.0/0"
  network      = google_compute_network.hub.name
  next_hop_ilb = google_compute_forwarding_rule.google_compute_forwarding_rule.id
  priority     = "800"
}