variable "project_id" {
  description = "The Project ID"
  type        = string
}

# Deploy central Firewall
resource "google_compute_instance" "pfsense-01" {
  name           = "pfsense-vm-01"
  machine_type   = "n1-standard-4"
  zone           = "us-central1-b"
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
    network    = google_compute_network.public.id
    subnetwork = google_compute_subnetwork.subnet1.id
    access_config {}
  }
  network_interface {
    network    = google_compute_network.private.id
    subnetwork = google_compute_subnetwork.subnet0.id
  }

  scheduling {
    preemptible       = true
    automatic_restart = false
  }
}

# Deploy a test instance in the private VPC
# without a public IP address
resource "google_compute_instance" "private-vm" {
  name         = "private-vm"
  machine_type = "g1-small"
  zone         = "us-central1-b"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-pro-cloud/ubuntu-pro-2004-lts"
    }
  }

  network_interface {
    network    = google_compute_network.private.id
    subnetwork = google_compute_subnetwork.subnet0.id
  }
  
  scheduling {
    preemptible       = true
    automatic_restart = false
  }
}