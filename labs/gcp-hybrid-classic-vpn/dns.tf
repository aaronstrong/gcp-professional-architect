module "dns-private-zone" {
  source     = "terraform-google-modules/cloud-dns/google"
  version    = "~> 3.0"
  project_id = var.project_id
  type       = "private"
  name       = format("%s-%s", "gcp", replace(var.domain_name, ".", "-"))
  domain     = format("%s.%s.", "gcp", var.domain_name)

  private_visibility_config_networks = [
    google_compute_network.hub.id
  ]

  recordsets = [
    {
      name = "apache"
      type = "A"
      ttl  = 300
      records = [
        google_compute_instance.apache.network_interface.0.network_ip
      ]
    }
  ]
}

resource "google_dns_policy" "default" {
  name                      = "inbound2-policy"
  enable_inbound_forwarding = true
  networks {
    network_url = google_compute_network.hub.id
  }
}

module "dns-forwarding-zone" {
  source     = "terraform-google-modules/cloud-dns/google"
  version    = "~> 3.0"
  project_id = var.project_id
  type       = "forwarding"
  name       = format("%s", replace(var.domain_name, ".", "-"))
  domain     = format("%s.", var.domain_name)

  private_visibility_config_networks = [
    google_compute_network.hub.id
  ]

  target_name_server_addresses = var.target_name_server_addresses
}