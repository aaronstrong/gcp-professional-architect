# -------------------------------------------------------------------
# DEPLOY AN INSTANCE WITH APACHE
# Create a VM instance that will run Apache on it
# -------------------------------------------------------------------
// Create a simple Web Server instance
resource "google_compute_instance" "apache" {
  project      = var.project_id
  machine_type = "n1-standard-2"
  zone         = var.zone
  name         = "private-apache"
  tags         = ["allow-internal"]
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
      size  = 10
      type  = "pd-standard"
    }
  }
  network_interface {
    network    = google_compute_network.hub.id
    subnetwork = google_compute_subnetwork.subnet0.id
    access_config {
      // Ephemeral public IP
    }
  }
  scheduling {
    preemptible       = true
    automatic_restart = false
  }

  metadata_startup_script = file("./installer/install_apache.sh")
}

output "apache_instance_address" {
  description = "The Apache instance IP address."
  value       = google_compute_instance.apache.network_interface
}
