# NAT

module "landing-nat-primary" {
  source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-cloudnat?ref=v27.0.0"
  project_id     = var.project_id
  region         = var.regions.primary
  name           = local.region_shortnames[var.regions.primary]
  router_create  = true
  router_name    = "prod-nat-${local.region_shortnames[var.regions.primary]}"
  router_network = module.landing-untrusted-vpc.network_name
}

module "landing-nat-secondary" {
  source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-cloudnat?ref=v27.0.0"
  project_id     = var.project_id
  region         = var.regions.secondary
  name           = local.region_shortnames[var.regions.secondary]
  router_create  = true
  router_name    = "prod-nat-${local.region_shortnames[var.regions.secondary]}"
  router_network = module.landing-untrusted-vpc.network_name
}