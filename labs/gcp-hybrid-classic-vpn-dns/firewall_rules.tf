# -------------------------------------------------------------------
# DEPLOY FIREWALL RULES
# -------------------------------------------------------------------

resource "google_compute_firewall" "allow-iap-private-network" {
  // Firewall Rule to allow IAP to private instances
  name          = "allow-iap-private-network"
  network       = google_compute_network.hub.name
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20", "192.168.0.0/16"]
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


resource "google_compute_firewall" "allow-dc" {
  # Rule to allow active directory ports
  name          = module.fw_dc_allow.id
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
  name          = module.fw_dns_allow.id
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