module "landing-dns-fwd-onprem-example" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/dns?ref=v27.0.0"
  project_id = var.project_id
  name       = "contoso-local"
  zone_config = {
    domain = "contoso.local."
    forwarding = {
      client_networks = [
        module.landing-untrusted-vpc.network_self_link,
        module.landing-trusted-vpc.network_self_link
      ]
      forwarders = { for ip in var.dns.onprem : ip => null }
    }
  }
}