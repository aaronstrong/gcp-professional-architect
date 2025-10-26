# -------------------------------------------------------------------
# WINDOWS TEST INSTANCE
# Create two windows machines
# -------------------------------------------------------------------

resource "google_compute_instance" "main" {
  for_each = var.list_instances

  name           = each.value.name
  machine_type   = each.value.machine_type
  zone           = "${var.region}-${each.value.zone}"
  can_ip_forward = false

  tags = ["dc", "dns", "wsfc", "wsfc-node"]

  boot_disk {
    initialize_params {
      image = var.boot_disk
    }
  }

  scheduling {
    preemptible       = each.value.preemptible
    automatic_restart = var.auto_restart
  }

  network_interface {
    network    = google_compute_network.hub.id
    subnetwork = google_compute_subnetwork.subnet0.id
    network_ip = google_compute_address.main[each.key].address
  }

  metadata = {
    test_vm                       = "true"
    enable-wsfc                   = "true" # this enables the WSFC agent to talk with the ILB
    ActiveDirectoryDnsDomain      = var.AdDnsDomain
    ActiveDirectoryNetbiosDomain  = var.AdNetbiosDomain
    instanceName                  = each.value.name
    sysprep-specialize-script-ps1 = local.scripts["specialize-node"]
    windows-startup-script-ps1    = local.scripts["join-domain"]
  }

  service_account {
    email  = google_service_account.main.email
    scopes = ["cloud-platform"]
  }
}

# -------------------------------------------------------------------
# UNMANAGED INSTANCE GROUP
# Each Windows server is assigned to its own UMIG
# -------------------------------------------------------------------

resource "google_compute_instance_group" "main" {
  for_each = var.list_instances

  name    = "${each.value.name}-umig-group"
  zone    = google_compute_instance.main[each.key].zone
  network = google_compute_network.hub.id
  project = var.project_id

  instances = [
    google_compute_instance.main[each.key].id
  ]
}

# -------------------------------------------------------------------
# Internal Load Balancer
# -------------------------------------------------------------------

resource "google_compute_forwarding_rule" "main" {
  project               = var.project_id
  name                  = "l4-ilb-wsfcnet-forwarding-rule"
  backend_service       = google_compute_region_backend_service.default.id
  ip_address            = google_compute_address.main["loadbalancer"].address
  provider              = google-beta
  region                = var.region
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL"
  ports                 = ["80"]
  network               = google_compute_network.hub.id
  subnetwork            = google_compute_subnetwork.subnet0.id
}

resource "google_compute_region_backend_service" "default" {
  name                            = "backed-wsfc-umig"
  region                          = var.region
  health_checks                   = [google_compute_health_check.main.id]
  connection_draining_timeout_sec = 10

  dynamic "backend" {
    for_each = google_compute_instance_group.main

    content {
      balancing_mode = "CONNECTION"
      group          = backend.value.self_link
    }
  }
}

# -------------------------------------------------------------------
# Health Check assigned to ILB
# -------------------------------------------------------------------

resource "google_compute_health_check" "main" {
  name = "wsfc-hc"

  timeout_sec        = 1
  check_interval_sec = 2

  tcp_health_check {
    request  = google_compute_address.main["loadbalancer"].address
    response = "1"
    port     = var.default_app_port
  }
}