# -------------------------------------------------------------------
# WINDOWS TEST INSTANCE
# -------------------------------------------------------------------

resource "google_compute_instance" "vm_test" {
  name         = "test-vm"
  machine_type = "n1-standard-2"
  zone         = "us-central1-c"

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
  }

  metadata = {
    test_vm = "true"
  }

  service_account {
    scopes = ["cloud-platform"]
  }
}

output "test-name" {
  description = "The name of the first domain controller."
  value       = google_compute_instance.vm_test.name
}

output "test-zone" {
  description = "The zone the domain controller is deployed into."
  value       = google_compute_instance.vm_test.zone
}