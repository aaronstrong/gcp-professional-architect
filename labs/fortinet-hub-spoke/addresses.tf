resource "google_compute_address" "ext_ip" {
  # External IP in Untrust VPC
  count = var.fgw_count != 0 ? var.fgw_count : 0

  project      = var.project_id
  name         = "${var.prefix}ip${count.index}-public-untrust"
  region       = var.regions.primary
  address_type = "EXTERNAL"
  labels = {
    resource = "fortinet"
  }
}

resource "google_compute_address" "ext_priv" {
  # Private IP in Untrust VPC
  count = var.fgw_count != 0 ? var.fgw_count : 0

  project      = var.project_id
  name         = "${var.prefix}ip${count.index}-untrust"
  region       = var.regions.primary
  address_type = "INTERNAL"
  subnetwork   = module.landing-untrusted-vpc.subnets["${var.regions.primary}/landing-untrusted-default-${local.region_shortnames[var.regions.primary]}"].self_link
}

resource "google_compute_address" "int_priv" {
  # Private IP in Trust VPC
  count = var.fgw_count != 0 ? var.fgw_count : 0

  project      = var.project_id
  name         = "${var.prefix}ip${count.index}-trust"
  region       = var.regions.primary
  address_type = "INTERNAL"
  subnetwork   = module.landing-trusted-vpc.subnets["${var.regions.primary}/landing-trusted-default-${local.region_shortnames[var.regions.primary]}"].self_link
}