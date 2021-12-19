# -------------------------------------------------------------------
# FIREWALL RULES
# GCP by default has a deny ingress rule. To allow traffic, you must
# create exceptions
# -------------------------------------------------------------------
// Rule to allow IAP into the hub VPC
resource "google_compute_firewall" "allow-iap-private-network" {
  name          = "allow-iap-private-network"
  network       = google_compute_network.hub.name
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]
  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }
}

# HUB VPC firewall rule
// Allow ingress into the untrust VPC
// (Best practice would be to NOT allow ALL traffic from any source and any protocol)
resource "google_compute_firewall" "allow-ingress-public-vpc" {
  name          = "allow-ingress-public-vpc"
  network       = google_compute_network.hub.name
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "all"
  }
}