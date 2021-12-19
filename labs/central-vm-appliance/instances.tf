# -------------------------------------------------------------------
# INSTANCES
# -------------------------------------------------------------------
# Deploy central Firewall
resource "google_compute_instance" "pfsense" {
  for_each       = toset(var.zone_spread)
  name           = "pfsense-${var.region}-${each.value}"
  machine_type   = "n1-standard-4"
  zone           = "${var.region}-${each.value}"
  can_ip_forward = true

  metadata = {
    #serial-port-logging-enabled = "TRUE"
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


# resource "google_compute_instance" "pfsense-02" {
#   name           = module.pfsense_two.id
#   machine_type   = "n1-standard-4"
#   zone           = "${var.region}-c"
#   can_ip_forward = true

#   metadata = {
#     #serial-port-logging-enabled = "TRUE"
#     serial-port-enable = true
#   }

#   boot_disk {
#     initialize_params {
#       image = "${var.project_id}/pfsense-2-5-2"
#       size  = 20
#       type  = "pd-standard"
#     }
#   }

#   network_interface {
#     network    = google_compute_network.hub.id
#     subnetwork = google_compute_subnetwork.subnet0.id
#     access_config {}
#   }

#   scheduling {
#     preemptible       = true
#     automatic_restart = false
#   }
# }
# Deploy a test instance in the private VPC
# without a public IP address
resource "google_compute_instance" "private-vm" {
  name         = "private-vm"
  machine_type = "g1-small"
  zone         = "${var.region}-b"

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