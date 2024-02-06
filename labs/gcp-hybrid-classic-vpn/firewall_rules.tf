# -------------------------------------------------------------------
# DEPLOY FIREWALL RULES
# -------------------------------------------------------------------

resource "google_compute_firewall" "allow-iap-private-network" {
  // Firewall Rule to allow IAP to private instances
  name          = "allow-iap-private-network"
  network       = google_compute_network.hub.name
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]
  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }
}

resource "google_compute_firewall" "allow-internal-traffic" {
  // Firewall Rule to allow private internal icmp
  name          = "allow-internal-traffic"
  network       = google_compute_network.hub.name
  direction     = "INGRESS"
  source_ranges = ["192.168.0.0/16", "172.16.0.0/12", "10.0.0.0/8"]
  source_tags   = ["allow-internal"]
  allow {
    protocol = "tcp"
    ports    = ["443", "80", "22"]
  }

  allow {
    protocol = "icmp"
  }
}