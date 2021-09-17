// CREATE A GROUP OF DISSIMILAR COMPUTE ENGINE INSTANCES
resource "google_compute_instance_group" "fw-umig-01" {
  name        = "firewall-umig-01"
  description = "Terraform unmanaged instance groups"
  zone        = "us-central1-b"
  network     = google_compute_network.public.id

  instances = [
    google_compute_instance.pfsense-01.id,
  ]
}

resource "google_compute_instance_group" "fw-umig-02" {
  name        = "firewall-umig-02"
  description = "Terraform unmanaged instance groups"
  zone        = "us-central1-c"
  network     = google_compute_network.public.id

  instances = [
    google_compute_instance.pfsense-02.id,
  ]
}

// CREATE HEALTH CHECK
resource "google_compute_health_check" "http" {
  name = "health-check-http"

  timeout_sec        = 5
  check_interval_sec = 10

  https_health_check {
    port = "443"
  }
}

// FIREWALL FOR HEALTH-CHECK
resource "google_compute_firewall" "default-hc" {
  project = var.project_id
  name    = "firewall-hc"
  network = google_compute_network.private.name
  allow {
    protocol = "tcp"
    ports    = ["443", "81"]
  }
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
}

resource "google_compute_firewall" "default-ilb-fw" {
  project = var.project_id
  name    = "firewall-ilb-fw"
  network = google_compute_network.private.name
  allow {
    protocol = "all"
  }
}

# // CREATE INTERNAL LOAD BALANCER
# forwarding rule
resource "google_compute_forwarding_rule" "google_compute_forwarding_rule" {
  project               = var.project_id
  name                  = "l4-ilb-forwarding-rule"
  description           = "managed by terraform"
  region                = "us-central1"
  network               = google_compute_network.private.id
  subnetwork            = google_compute_subnetwork.subnet0.id
  allow_global_access   = false
  backend_service       = google_compute_region_backend_service.umig.self_link
  provider              = google-beta
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL"
  all_ports             = true
}

# region backend
resource "google_compute_region_backend_service" "umig" {
  name                            = "firewall-with--tcp-hc"
  project                         = var.project_id
  provider                        = google-beta
  region                          = "us-central1"
  protocol                        = "TCP"
  load_balancing_scheme           = "INTERNAL"
  network                         = google_compute_network.private.id
  health_checks                   = [google_compute_health_check.http.id]
  connection_draining_timeout_sec = 300
  backend {
    group       = google_compute_instance_group.fw-umig-01.self_link
    description = "Instance Group 1"
    failover    = false
  }
  backend {
    group       = google_compute_instance_group.fw-umig-02.self_link
    description = "Instance Group 2"
    failover    = true
  }
  # failover_policy {
  #   disable_connection_drain_on_failover = true
  #   drop_traffic_if_unhealthy            = true
  # }
}




# module "gce-ilb" {
#   depends_on = [
#     google_compute_network.private
#   ]
#   source     = "GoogleCloudPlatform/lb-internal/google"
#   project    = var.project_id
#   version    = "~> 4.0"
#   network    = google_compute_network.private.name
#   subnetwork = google_compute_subnetwork.subnet0.name
#   region     = "us-central1"
#   name       = "group2-ilb"
#   ports      = []
#   all_ports  = true
#   health_check = {
#     type                = "http"
#     check_interval_sec  = 1
#     healthy_threshold   = 4
#     timeout_sec         = 1
#     unhealthy_threshold = 5
#     response            = ""
#     proxy_header        = "NONE"
#     port                = 80
#     port_name           = "health-check-port"
#     request             = ""
#     request_path        = "/"
#     host                = "1.2.3.4"
#     enable_log          = false
#   }
#   source_tags = []
#   target_tags = []
#   backends = [
#     { group = google_compute_instance_group.fw-umig-01.id, description = "", failover = false },
#     { group = google_compute_instance_group.fw-umig-02.id, description = "", failover = true },
#   ]
# }