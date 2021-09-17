# Rule to allow IAP into the private VPC
resource "google_compute_firewall" "allow-iap-private-network" {
  name          = "allow-iap-private-network"
  network       = google_compute_network.private.name
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]
  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }
}

# Private VPC rules
resource "google_compute_firewall" "private-vpc-for-all" {
  name          = "private-vpc-for-all"
  network       = google_compute_network.private.name
  direction     = "INGRESS"
  source_ranges = ["10.0.0.0/8"]

  allow {
    protocol = "all"
  }
}

# PUBLIC VPC FIREWALL RULES
resource "google_compute_firewall" "allow-ingress-public-vpc" {
  name          = "allow-ingress-public-vpc"
  network       = google_compute_network.public.name
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "all"
  }
}