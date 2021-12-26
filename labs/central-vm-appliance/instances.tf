# -------------------------------------------------------------------
# DATA RESOURCES
# -------------------------------------------------------------------

data "google_compute_zones" "available" {
  region = var.region
}

# -------------------------------------------------------------------
# LOCALS
# -------------------------------------------------------------------

locals {
  firewall_name = format("%s-%s-%s", var.environment, "pfsense", var.region)
  instance_name = format("%s-%s", var.environment, "instance")
}

# -------------------------------------------------------------------
# INSTANCES
# -------------------------------------------------------------------
# Deploy central Firewall
resource "google_compute_instance" "pfsense" {
  #for_each       = toset(var.zone_spread)
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
    network    = google_compute_network.hub.id
    subnetwork = google_compute_subnetwork.subnet0.id
    access_config {}
    // reserve an internal static ip
  }

  scheduling {
    preemptible       = true
    automatic_restart = false
  }
}

# Deploy a test instance in the private VPC
# without a public IP address
resource "google_compute_instance" "private-vm" {
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
    network    = google_compute_network.hub.id
    subnetwork = google_compute_subnetwork.subnet0.id
  }

  scheduling {
    preemptible       = true
    automatic_restart = false
  }
}