# -------------------------------------------------------------------
# FIREWALL RULES
# The domain controllers need lots of different ports open. Create
# a firewall ruleset for Active Directory (dc) and another ruleset
# for DNS.
# -------------------------------------------------------------------

resource "google_compute_firewall" "allow-iap-private-network" {
  # Rule to allow IAP into the private VPC
  name          = module.fw_iap_allow.id
  network       = google_compute_network.hub.name
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20", "192.168.0.0/16", "0.0.0.0/0"]
  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
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
    ports    = ["88", "135", "389", "445", "464", "636", "3268", "3269", "9389", "49152-65535"] #9389 is Active Directory Web Services
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

resource "google_compute_firewall" "wsfc_nodes" {
  name        = "allow-all-between-wsfc-nodes"
  network     = google_compute_network.hub.name
  direction   = "INGRESS"
  source_tags = ["wsfc"]
  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }
  target_tags = ["wsfc"]
}


resource "google_compute_firewall" "allow_health_check" {
  # Rule to allow health Checks from the IP ranges of the Google Cloud Providers
  name          = "allow-health-checks"
  network       = google_compute_network.hub.name
  direction     = "INGRESS"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16", "10.0.0.0/8"]
  allow {
    protocol = "tcp"
    ports    = ["80", "443", var.default_app_port]
  }
  target_tags = ["wsfc-node", "dc"]
}

resource "google_compute_firewall" "allow_mskms" {
  name               = "allow-mskms-ipv4-firewall-rule"
  network            = google_compute_network.hub.name
  direction          = "EGRESS"
  source_ranges      = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", ]
  destination_ranges = ["35.190.247.13/32"]

  allow {
    protocol = "tcp"
    ports    = ["1688"]
  }

  priority = 0
}