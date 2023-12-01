module "dev-spoke-project2" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 14.4"

  name              = "dev-net-spoke-1"
  random_project_id = true
  org_id            = var.org_id
  folder_id         = var.folder_id
  billing_account   = var.billing_account

  activate_apis = [
    "compute.googleapis.com",
    "dns.googleapis.com",
    "iap.googleapis.com",
    "networkmanagement.googleapis.com",
    "servicenetworking.googleapis.com",
    "stackdriver.googleapis.com",
    "vpcaccess.googleapis.com"
  ]

  enable_shared_vpc_host_project = true
}

module "dev-spoke-vpc2" {
  source  = "terraform-google-modules/network/google"
  version = "~> 8.0"

  project_id   = module.dev-spoke-project2.project_id
  network_name = "dev-net-spoke-0"
  routing_mode = "GLOBAL"

  delete_default_internet_gateway_routes = true

  subnets = [
    {
      subnet_name           = "dev-default-uc1"
      subnet_ip             = "10.68.253.0/24"
      subnet_region         = "us-central1"
      description           = "This subnet has a description for dev"
      subnet_private_access = "true"
    },
  ]
}

module "spoke2-vpc-fireall-rules" {
  source       = "terraform-google-modules/network/google//modules/firewall-rules"
  version      = "~> 7.2"
  project_id   = module.dev-spoke-project2.project_id
  network_name = module.dev-spoke-vpc2.network_self_link
  rules = [
    {
      name          = "allow-most-protocol"
      description   = "Allow most popular protocols for testing, managed by Terraform"
      direction     = "INGRESS"
      priority      = null
      source_ranges = ["0.0.0.0/0"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["22", "80", "443"]
        },
        {
          protocol = "icmp"
        }
      ]
    }
  ]
}

module "vpn_ha-1" {
  source           = "terraform-google-modules/vpn/google//modules/vpn_ha"
  version          = "~> 4.0"
  project_id       = module.dev-spoke-project2.project_id
  region           = var.regions.primary
  network          = module.dev-spoke-vpc2.network_self_link
  name             = "spoke2-net-to-trusted-net"
  peer_gcp_gateway = module.vpn_ha-2.self_link
  router_asn       = 64514

  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.1"
        asn     = 64513
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.1.2/30"
      ike_version                     = 2
      vpn_gateway_interface           = 0
      peer_external_gateway_interface = null
      shared_secret                   = ""
    }
  }


}

module "vpn_ha-2" {
  source           = "terraform-google-modules/vpn/google//modules/vpn_ha"
  version          = "~> 4.0"
  project_id       = var.project_id
  region           = var.regions.primary
  network          = module.landing-trusted-vpc.network_self_link
  name             = "trusted-net-to-spoke2-net"
  router_asn       = 64513
  peer_gcp_gateway = module.vpn_ha-1.self_link

  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.2"
        asn     = 64514
      }
      bgp_session_range     = "169.254.1.1/30"
      ike_version           = 2
      vpn_gateway_interface = 0
      shared_secret         = module.vpn_ha-1.random_secret
    }
  }

  router_advertise_config = {
    groups = ["ALL_SUBNETS"]
    ip_ranges = {
      "0.0.0.0/0" = "Default Route"
    }
    mode = "CUSTOM"
  }
}

# --------------------------------------------------------------------
# Spoke 2 Dev
# Test Resources
# --------------------------------------------------------------------

module "test-vm-spoke2-vnet-primary-0" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/compute-vm?ref=v27.0.0"
  project_id = module.dev-spoke-project2.project_id
  zone       = "${var.regions.primary}-b"
  name       = "spoke2-vnet-pri-0"
  network_interfaces = [{
    network    = module.dev-spoke-vpc2.network_self_link
    subnetwork = module.dev-spoke-vpc2.subnets_self_links[0]
  }]
  tags = ["primary", "ssh"]
  service_account = {
    auto_create = true
  }
  boot_disk = {
    initialize_params = {
      image = "projects/debian-cloud/global/images/family/debian-10"
    }
  }
  options = {
    spot               = true
    termination_action = "STOP"
  }
  metadata = {
    startup-script = <<EOF
      apt update
      apt install iputils-ping bind9-dnsutils
    EOF
  }
}

# --------------------------------------------------------------------
# Spoke 2 Dev
# Outputs
# --------------------------------------------------------------------

# ... here