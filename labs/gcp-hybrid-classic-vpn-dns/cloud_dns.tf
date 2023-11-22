# -------------------------------------------------------------------
# DEPLOY CLOUD DNS
# Use Cloud DNS and forward any internal requests to the two
# Domain Controllers
# -------------------------------------------------------------------
resource "google_dns_managed_zone" "private-zone" {
  name        = "private-zone"
  dns_name    = "contoso.local."
  description = "Example private DNS zone"
  visibility  = "private"
  labels = {
    foo = "bar"
  }

  private_visibility_config {
    networks {
      network_url = google_compute_network.hub.id
    }
  }

  forwarding_config {
    # Forward DNS requests to the domain controllers
    target_name_servers {
      ipv4_address = google_compute_address.us_central.address
    }
    target_name_servers {
      ipv4_address = "192.168.2.90" # on-prem Domain Controller
    }
  }

  depends_on = [google_project_service.project]
}