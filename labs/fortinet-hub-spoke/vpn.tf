# -------------------------------------------------------------------
# DEPLOY A CLASSIC VPN IN GCP
# This is an exmaple of deploying a classic based VPN in GCP back to
# an on-premises data center.
# -------------------------------------------------------------------

# Auto-detect your own IP address to add it to the `peer_ips`
data "http" "my_ip" {
  url = "http://api.ipify.org"
}

# Deploy a cloud router that will be attached to the classic VPN
resource "google_compute_router" "cloud_router" {
  count   = var.toggle_cloud_vpn == true ? 1 : 0
  name    = "cr-${var.regions.primary}-to-prod-vpc-tunnels"
  region  = var.regions.primary
  network = module.landing-trusted-vpc.subnets["${var.regions.primary}/landing-trusted-default-uc1"].network
  project = var.project_id
}

module "classic_vpn" {
  count = var.toggle_cloud_vpn == true ? 1 : 0
  # Deploy the classic VPN in GCP using the GCP module. Pin the Github
  # module to a specific version
  source  = "terraform-google-modules/vpn/google"
  version = "~> 3.0"

  project_id         = var.project_id
  network            = module.landing-trusted-vpc.network_name
  region             = var.regions.primary
  gateway_name       = "vpn-managed-internal"
  tunnel_name_prefix = "vpn-tn-manage-internal"
  shared_secret      = var.shared_secret
  tunnel_count       = 1
  peer_ips           = ["${data.http.my_ip.response_body}"]
  route_priority     = 1000
  remote_subnet      = var.remote_subnet
  ike_version        = 2
}

