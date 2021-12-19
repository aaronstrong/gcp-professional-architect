# -------------------------------------------------------------------
# VPC
# Create the four VPCs and assign subnet ranges to each.
# -------------------------------------------------------------------
// Create a Hub VPC
resource "google_compute_network" "hub" {
  name                    = module.vpc_hub.id
  auto_create_subnetworks = false
}

// Create a subnetwork in the hub VPC
resource "google_compute_subnetwork" "subnet0" {
  name          = module.vpc_subnet.id
  ip_cidr_range = cidrsubnet(var.cidr_prefix, 9, 0)
  region        = var.region
  network       = google_compute_network.hub.id
}