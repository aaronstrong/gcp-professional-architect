# -------------------------------------------------------------------
# ACTIVE DIRECTORY
# Create the first instance used as the Domain Controller.
# This instance will also host the shared folder for a file share witness
# -------------------------------------------------------------------

resource "google_compute_instance" "dc-1" {
  // You would not make a production ADDC public to the internet. BUT, this is a lab :)
  #name           = module.gce_dc_one.id
  name         = var.dc_name
  machine_type = var.dc_machine_type
  zone         = "${var.region}-b"
  tags         = ["dc", "dns"]
  labels = {
    "owner"       = "dc"
    "application" = "active_directory"
  }
  can_ip_forward = true

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
    network_ip = google_compute_address.main["dc1"].address
    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    active_directory              = "true"
    ActiveDirectoryDnsDomain      = var.AdDnsDomain
    ActiveDirectoryNetbiosDomain  = var.AdNetbiosDomain
    ActiveDirectoryFirstDc        = module.gce_dc_one.id
    sysprep-specialize-script-ps1 = "Install-WindowsFeature AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools; Install-WindowsFeature DNS -IncludeAllSubFeature -IncludeManagementTools; Install-WindowsFeature GPMC -IncludeAllSubFeature -IncludeManagementTools"
    windows-startup-script-ps1    = local.scripts["dc-startup"]
  }

  service_account {
    email  = google_service_account.main.email
    scopes = ["cloud-platform"]
  }
}
