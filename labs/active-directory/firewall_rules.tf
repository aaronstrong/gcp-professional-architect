
# -------------------------------------------------------------------
# FIREWALL RULES
# The domain controllers need lots of different ports open. Create
# a firewall ruleset for Active Directory (dc) and another ruleset
# for DNS.
# -------------------------------------------------------------------

resource "google_compute_firewall" "allow-iap-private-network" {
  # Rule to allow IAP into the private VPC
  name          = "allow-iap-private-network"
  network       = google_compute_network.hub.name
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20", "0.0.0.0/0"]
  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }
}

resource "google_compute_firewall" "allow-dc" {
  # Rule to allow active directory ports
  name          = "allow-dc"
  network       = google_compute_network.hub.name
  direction     = "INGRESS"
  source_ranges = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  allow {
    protocol = "tcp"
    ports    = ["88", "135", "389", "445", "464", "636", "3268", "3269", "49152-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["88", "123", "389", "464"]
  }
  allow {
    protocol = "icmp"
  }
  target_tags = ["dc"]
}

resource "google_compute_firewall" "dns" {
  # Rule to allow DNS ports
  name          = "allow-dns"
  network       = google_compute_network.hub.name
  direction     = "INGRESS"
  source_ranges = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "35.199.192.0/19"]
  allow {
    protocol = "tcp"
    ports    = ["53"]
  }
  allow {
    protocol = "udp"
    ports    = ["53"]
  }
  target_tags = ["dns"]
}