locals {
  _functions = templatefile("${path.module}/scripts/functions.ps1", local._template_vars0)
  _scripts = [
    "specialize-node",
    "join-domain",
    "dc-startup"
  ]

  _template_vars0 = {
    secret_id                     = var.secret_id
    ad_domain                     = var.AdDnsDomain
    ad_netbios                    = var.AdNetbiosDomain
    health_check_port             = var.default_app_port
    cluster_ip                    = google_compute_address.main["cluster_ip"].address
    loadbalancer_ip               = google_compute_address.main["loadbalancer"].address
    node1_ip                      = google_compute_address.main["wsfc1"].address
    node2_ip                      = google_compute_address.main["wsfc2"].address
    node_netbios_1                = var.list_instances["wsfc1"].name
    node_netbios_2                = var.list_instances["wsfc2"].name
    witness_netbios               = "test-dc-01"
    cluster_name                  = var.cluster_name #NetBIOS Name
    cluster_full                  = var.cluster_name
    cluster_user_name             = var.cluster_username
    cluster_admin_password_secret = var.cluster_password
    managed_ad_dn_path            = var.managed_ad_dn != "" ? "-Path \"${var.managed_ad_dn}\"" : ""
    managed_ad_dn                 = var.managed_ad_dn
  }

  scripts = {
    for script in local._scripts :
    script => templatefile("./scripts/${script}.ps1", local._template_vars)
  }
  _template_vars = merge(local._template_vars0, {
    functions = local._functions
  })
}

# -------------------------------------------------------------------
# PROJECT APIS
# Enable necessary APIs
# -------------------------------------------------------------------

resource "google_project_service" "main" {
  for_each = toset(var.project_services)
  project  = var.project_id
  service  = each.value
}

# -------------------------------------------------------------------
# VPC
# Create a VPC
# -------------------------------------------------------------------

resource "google_compute_network" "hub" {
  name                    = module.vpc_hub.id
  auto_create_subnetworks = false
}

# -------------------------------------------------------------------
# CREATE SUBNETS
# Create two different subnets and CIDR blocks in different regions
# -------------------------------------------------------------------

resource "google_compute_subnetwork" "subnet0" {
  # Creaet the first subnet in region
  name                     = module.vpc_subnet_01.id
  ip_cidr_range            = cidrsubnet(var.cidr_prefix, 1, 0)
  region                   = var.region
  network                  = google_compute_network.hub.id
  private_ip_google_access = true
}

# -------------------------------------------------------------------
# CREATE ROUTES
# Create a route to MS KMS in Google
# -------------------------------------------------------------------

resource "google_compute_route" "main" {
  name             = "mskms-ipv4-route"
  dest_range       = "35.190.247.13/32"
  network          = google_compute_network.hub.id
  next_hop_gateway = "default-internet-gateway"
  priority         = 100
}

# -------------------------------------------------------------------
# Reserve IPs
# -------------------------------------------------------------------

resource "google_compute_address" "main" {
  for_each = var.list_reserved_ips

  name         = each.value.name
  address_type = "INTERNAL"
  address      = cidrhost(google_compute_subnetwork.subnet0.ip_cidr_range, each.value.address)
  region       = google_compute_subnetwork.subnet0.region
  subnetwork   = google_compute_subnetwork.subnet0.id
}

# -------------------------------------------------------------------
# DEPLOY CLOUD DNS
# Use Cloud DNS and forward any internal requests to the two
# Domain Controllers
# -------------------------------------------------------------------

resource "google_dns_managed_zone" "private-zone" {
  name        = "private-zone"
  dns_name    = "${var.AdDnsDomain}."
  description = "Example private DNS zone"
  visibility  = "private"
  labels = {
    foo = "bar"
  }

  private_visibility_config {
    networks {
      network_url = google_compute_network.hub.id
    }
  }

  forwarding_config {
    # Forward DNS requests to the domain controllers
    target_name_servers {
      ipv4_address = google_compute_address.main["dc1"].address
    }
  }
}

# -------------------------------------------------------------------
# SECRETS MANAGER
# Generate a secret to be read by SA and applied to AD DS deployment
# -------------------------------------------------------------------

resource "random_password" "main" {
  length           = 10
  special          = true
  override_special = "!#$%&*():?"
}

resource "google_secret_manager_secret" "main" {
  secret_id = var.secret_id

  project = var.project_id

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  depends_on = [
    google_project_service.main
  ]
}

resource "google_secret_manager_secret_version" "main" {
  secret      = google_secret_manager_secret.main.id
  secret_data = random_password.main.result
}

# -------------------------------------------------------------------
# SERVICE ACCOUNT
# Generate a service account
# -------------------------------------------------------------------

resource "google_service_account" "main" {
  account_id   = "ad-domaincontroller"
  display_name = "AD Domain Controller"
  project      = var.project_id
}

resource "google_secret_manager_secret_iam_member" "name" {
  secret_id = google_secret_manager_secret.main.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.main.email}"
}