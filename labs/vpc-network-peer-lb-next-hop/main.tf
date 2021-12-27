# -------------------------------------------------------------------
# PROVIDER
# -------------------------------------------------------------------

provider "google" {
  project = var.project_id
  region  = var.region
}

# -------------------------------------------------------------------
# DATA RESOURCES
# -------------------------------------------------------------------

data "google_netblock_ip_ranges" "legacy_health_checkers" {
  range_type = "legacy-health-checkers"
}

data "google_netblock_ip_ranges" "health_checkers" {
  range_type = "health-checkers"
}

data "google_netblock_ip_ranges" "iap_forwarders" {
  range_type = "iap-forwarders"
}

data "google_compute_zones" "available" {
  region = var.region
}

# -------------------------------------------------------------------
# LOCALS
# -------------------------------------------------------------------

locals {
  firewall_name               = format("%s-%s-%s", var.environment, "pfsense", var.region)
  instance_name               = format("%s-%s", var.environment, "test")
  protocol                    = upper("TCP")
  direction_ingress           = upper("INGRESS")
  fw_name_ingress_iap         = "allow-ingress-iap-${local.spoke_a_vpc_name}"
  fw_name_ingress_untrust     = "allow-ingress-all-${local.untrust_vpc_name}"
  fw_name_ingress_all_spoke_a = "allow-ingres-all-${local.spoke_a_vpc_name}"
  fw_name_ingress_all_hub     = "allow-ingress-all-${local.hub_vpc_name}"
}

# -------------------------------------------------------------------
# FIREWALL RULES
# Create a firewall rule to allow inbound IAP access.
# -------------------------------------------------------------------

resource "google_compute_firewall" "allow-iap-private-network" {
  # Rule to allow IAP into the private VPC
  name          = local.fw_name_ingress_iap
  network       = google_compute_network.spoke-a.name
  direction     = local.direction_ingress
  source_ranges = concat(data.google_netblock_ip_ranges.iap_forwarders.cidr_blocks_ipv4)
  allow {
    protocol = local.protocol
    ports    = ["22", "3389"]
  }
}

# Public VPC firewall rule
# Allow ingress into the untrust VPC
# (Best practice would be to NOT allow ALL traffic from any source and any protocol)
resource "google_compute_firewall" "allow-ingress-public-vpc" {
  name          = local.fw_name_ingress_untrust
  network       = google_compute_network.untrust.name
  direction     = local.direction_ingress
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "all"
  }
}

# All ingress into spoke-a vpc
resource "google_compute_firewall" "allow-ingress-spoke-a-vpc" {
  name          = local.fw_name_ingress_all_spoke_a
  network       = google_compute_network.spoke-a.name
  direction     = local.direction_ingress
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "all"
  }
}

# All ingress into hub vpc
resource "google_compute_firewall" "allow-ingress-hub-vpc" {
  name          = local.fw_name_ingress_all_hub
  network       = google_compute_network.hub.name
  direction     = local.direction_ingress
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "all"
  }
}

# Firewall rule for the GCP Health-check
resource "google_compute_firewall" "default-hc" {
  project = var.project_id
  name    = "firewall-hc"
  network = google_compute_network.hub.name
  allow {
    protocol = local.protocol
    ports    = ["443", "80"]
  }
  source_ranges = concat(data.google_netblock_ip_ranges.health_checkers.cidr_blocks_ipv4, data.google_netblock_ip_ranges.legacy_health_checkers.cidr_blocks_ipv4)
}

# Firewall rule to allow ingress for the hub vpc
resource "google_compute_firewall" "default-ilb-fw" {
  project = var.project_id
  name    = "firewall-ilb-fw"
  network = google_compute_network.hub.name
  allow {
    protocol = "all"
  }
}

# -------------------------------------------------------------------
# INSTANCES
# -------------------------------------------------------------------
# Deploy central Firewall
resource "google_compute_instance" "pfsense" {
  count          = var.firewalls_count
  name           = "${local.firewall_name}-${count.index}"
  machine_type   = "n1-standard-4"
  zone           = data.google_compute_zones.available.names[count.index]
  can_ip_forward = true

  metadata = {
    serial-port-enable = true
  }

  boot_disk {
    initialize_params {
      image = "${var.project_id}/pfsense-2-5-2"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    # reserve an internal static ip
    network    = google_compute_network.untrust.id
    subnetwork = google_compute_subnetwork.subnet1.id
    network_ip = cidrhost(local.untrust_cidr, (2 + count.index))
    access_config {}
  }
  network_interface {
    # reserve an internal static ip
    network    = google_compute_network.hub.id
    subnetwork = google_compute_subnetwork.subnet0.id
    network_ip = cidrhost(local.hub_cidr, (2 + count.index))
  }
  network_interface {
    network    = google_compute_network.transit.id
    subnetwork = google_compute_subnetwork.subnet2.id
    network_ip = cidrhost(local.transit_cidr, (2 + count.index))
  }

  scheduling {
    preemptible       = true
    automatic_restart = false
  }
}

resource "google_compute_instance" "private-vm" {
  # Deploy a test instance in the private VPC without a public IP address
  count        = var.instances_count
  name         = "${local.instance_name}-${count.index}"
  machine_type = "g1-small"
  zone         = data.google_compute_zones.available.names[count.index]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-pro-cloud/ubuntu-pro-2004-lts"
    }
  }

  network_interface {
    network    = google_compute_network.spoke-a.id
    subnetwork = google_compute_subnetwork.subnet3.id
  }

  scheduling {
    preemptible       = true
    automatic_restart = false
  }
}

# -------------------------------------------------------------------
# UNMANAGED INSTANCE GROUPS
#
# These firewalls are stateful and to prevent asymmetric routing,
# traffic needs to be sent to one firewall at a time. Two firewalls
# will be deployed, but one will be placed in an instance group marked
# for failover purpose only.
# -------------------------------------------------------------------
# Create two instance groups (IG) and put a stateful firewall in each IG
# Instance Group 1
resource "google_compute_instance_group" "fw_umig" {
  count       = var.firewalls_count
  name        = "firewall-umig-${count.index}"
  description = "Terraform unmanaged instance groups"
  zone        = data.google_compute_zones.available.names[count.index]
  network     = google_compute_network.untrust.id

  instances = [
    google_compute_instance.pfsense[count.index].id,
  ]
}

resource "google_compute_health_check" "http" {
  # Create the GCP Health Check
  name               = "health-check-http"
  timeout_sec        = 5
  check_interval_sec = 10

  https_health_check {
    port = "443"
  }
}

# CREATE INTERNAL LOAD BALANCER
# forwarding rule
resource "google_compute_forwarding_rule" "google_compute_forwarding_rule" {
  project               = var.project_id
  name                  = "l4-ilb-forwarding-rule"
  description           = "managed by terraform"
  region                = var.region
  network               = google_compute_network.hub.id
  subnetwork            = google_compute_subnetwork.subnet0.id
  allow_global_access   = false
  backend_service       = google_compute_region_backend_service.umig.self_link
  provider              = google-beta
  ip_protocol           = local.protocol
  load_balancing_scheme = "INTERNAL"
  all_ports             = true
}

# region backend
resource "google_compute_region_backend_service" "umig" {
  name                            = "firewall-with--tcp-hc"
  project                         = var.project_id
  provider                        = google-beta
  region                          = var.region
  protocol                        = local.protocol
  load_balancing_scheme           = "INTERNAL"
  network                         = google_compute_network.hub.id
  health_checks                   = [google_compute_health_check.http.id]
  connection_draining_timeout_sec = 300
  backend {
    group       = google_compute_instance_group.fw_umig[0].self_link
    description = format("Instance Group %s", "1")
    failover    = false
  }
  backend {
    group       = google_compute_instance_group.fw_umig[1].self_link
    description = format("Instance Group %s", "2")
    failover    = true
  }
}