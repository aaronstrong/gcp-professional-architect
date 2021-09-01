// Create custom VPC
resource "google_compute_network" "private" {
  name                    = "private-network"
  auto_create_subnetworks = false
}

// Create a subnetwork for the custom VPC
resource "google_compute_subnetwork" "subnet0" {
  name          = "subnet0"
  ip_cidr_range = "10.128.0.0/16"
  region        = "us-central1"
  network       = google_compute_network.private.id
  # secondary_ip_range {
  #     range_name = "kubernetes-pods"
  #     ip_cidr_range = ""
  # }
  # secondary_ip_range {
  #     range_name = "kubernetes-services"
  #     ip_cidr_range = ""
  # }
}

// Create the cluster
resource "google_service_account" "default" {
  account_id   = "service-account-id"
  display_name = "Service Account"
}

resource "google_container_cluster" "primary" {
  name     = "my-gke-cluster"
  location = "us-central1"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
  network                  = google_compute_network.private.name
  subnetwork               = google_compute_subnetwork.subnet0.name
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "my-node-pool"
  location   = "us-central1"
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "e2-medium"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.default.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}