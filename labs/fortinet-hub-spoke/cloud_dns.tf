# -------------------------------------------------------------------
# DEPLOY CLOUD DNS
# Use Cloud DNS and forward any internal requests to the two
# Domain Controllers
# -------------------------------------------------------------------

module "dns_fwd_onprem" {
  count      = var.enable_cloud_dns == true ? 1 : 0
  source     = "terraform-google-modules/cloud-dns/google"
  version    = "~> 5.0"
  project_id = var.project_id
  type       = "private"
  name       = var.dns_assigned_name
  domain     = var.dns_managed_zonename
  private_visibility_config_networks = [
    module.landing-trusted-vpc.subnets["us-central1/landing-trusted-default-uc1"].network,
    module.landing-untrusted-vpc.subnets["us-central1/landing-untrusted-default-uc1"].network
  ]

  target_name_server_addresses = var.target_name_server_addresses
}

module "dns_fwd_onprem_rev_10" {
  // Reverse DNS config
  count      = var.enable_cloud_dns == true ? 1 : 0
  source     = "terraform-google-modules/cloud-dns/google"
  version    = "~> 5.0"
  project_id = var.project_id
  type       = "private"
  name       = "root-reverse-10"
  domain     = "10.in-addr.arpa."

  private_visibility_config_networks = [
    module.landing-trusted-vpc.subnets["us-central1/landing-trusted-default-uc1"].network,
    module.landing-untrusted-vpc.subnets["us-central1/landing-untrusted-default-uc1"].network
  ]

  target_name_server_addresses = var.target_name_server_addresses
}

module "dns_priv_gcp" {
  count      = var.enable_cloud_dns == true ? 1 : 0
  source     = "terraform-google-modules/cloud-dns/google"
  version    = "~> 5.0"
  project_id = var.project_id
  type       = "private"
  name       = "gcp-contoso-local"
  domain     = "gcp.contoso.local."

  private_visibility_config_networks = [
    module.landing-trusted-vpc.subnets["us-central1/landing-trusted-default-uc1"].network,
    module.landing-untrusted-vpc.subnets["us-central1/landing-untrusted-default-uc1"].network
  ]

  recordsets = [{
    # name    = ""
    # type    = "NS"
    # ttl     = 300
    # records = ["127.0.0.1", ]
    # }, {
    name    = "localhost"
    type    = "A"
    ttl     = 300
    records = ["127.0.0.1", ]
  }, ]
}