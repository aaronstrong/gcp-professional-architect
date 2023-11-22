
# -------------------------------------------------------------
# RESERVE STATIC IP ADDRESS
# Reserve two static ip address for both Active Directory
# Domain Controllers.
# -------------------------------------------------------------

resource "google_compute_address" "us_central" {
  name         = "reservation-1"
  address_type = "INTERNAL"
  address      = cidrhost(google_compute_subnetwork.subnet0.ip_cidr_range, var.static_ip)
  region       = google_compute_subnetwork.subnet0.region
  subnetwork   = google_compute_subnetwork.subnet0.id
}

# -------------------------------------------------------------------
# ACTIVE DIRECTORY
# Create the first instance used as the Domain Controller.
# -------------------------------------------------------------------

resource "google_compute_instance" "dc-1" {
  // You would not make a production ADDC public to the internet. BUT, this is a lab :)
  name         = module.gce_dc_one.id
  machine_type = var.dc_machine_type
  zone         = "us-central1-b"
  tags         = ["dc", "dns"]
  labels       = module.gce_dc_one.tags

  boot_disk {
    initialize_params {
      image = var.boot_disk
    }
  }

  scheduling {
    preemptible       = var.preemptible
    automatic_restart = var.auto_restart
  }

  network_interface {
    network    = google_compute_network.hub.id
    subnetwork = google_compute_subnetwork.subnet0.id
    network_ip = google_compute_address.us_central.address
    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    active_directory           = "true"
    windows-startup-script-ps1 = file("./install-adds.ps1")
  }

  service_account {
    scopes = ["cloud-platform"]
  }
}