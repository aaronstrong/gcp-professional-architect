# -------------------------------------------------------------------
# DEPLOY A CLASSIC VPN IN GCP
# This is an exmaple of deploying a classic based VPN in GCP back to
# an on-premises data center.
# -------------------------------------------------------------------
# Deploy a cloud router that will be attached to the classic VPN
resource "google_compute_router" "cr-us-central1" {
  name    = "cr-us-central1-to-prod-vpc-tunnels"
  region  = var.region
  network = google_compute_network.hub.name
  project = var.project_id
}

module "classic_vpn" {
  # Deploy the classic VPN in GCP using the GCP module. Pin the Github
  # module to a specific version
  source  = "terraform-google-modules/vpn/google"
  version = "~> 2.0"

  project_id         = var.project_id
  network            = google_compute_network.hub.name
  region             = var.region
  gateway_name       = "vpn-managed-internal"
  tunnel_name_prefix = "vpn-tn-manage-internal"
  shared_secret      = var.shared_secret
  tunnel_count       = 1
  peer_ips           = var.peer_ips
  route_priority     = 1000
  remote_subnet      = var.remote_subnet
  ike_version        = 2
}