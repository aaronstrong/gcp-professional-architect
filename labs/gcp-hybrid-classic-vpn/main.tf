# -------------------------------------------------------------------
# PREPARE PROVIDERS
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
# DEPLOY A VPC
# -------------------------------------------------------------------
resource "google_compute_network" "hub" {
  # Create a Hub VPC
  name                    = "hub-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet0" {
  # Create a subnetwork in the hub VPC
  name          = "subnet0"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.hub.id
}