module "dev-spoke-project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 14.4"

  name              = "dev-net-spoke-0"
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

module "dev-spoke-vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 8.0"

  project_id   = module.dev-spoke-project.project_id
  network_name = "dev-net-spoke-0"
  routing_mode = "GLOBAL"

  delete_default_internet_gateway_routes = true

  subnets = [
    {
      subnet_name           = "dev-default-uc1"
      subnet_ip             = "10.68.0.0/24"
      subnet_region         = "us-central1"
      description           = "This subnet has a description for dev"
      subnet_private_access = "true"
    },
    {
      subnet_name           = "dev-default-ue1"
      subnet_ip             = "10.84.0.0/24"
      subnet_region         = "us-east1"
      description           = "This subnet has a description for dev"
      subnet_private_access = "true"
    }
  ]

  # routes = [
  #   {
  #     name              = "nva-primary-to-primary"
  #     description       = "route description"
  #     destination_range = "0.0.0.0/0"
  #     priority          = 1000
  #     tags              = "primary"
  #     next_hop_ilb = "https://www.googleapis.com/compute/v1/projects/appmod-astro-c94d/regions/us-central1/forwardingRules/nva-trusted-primary"
  #     #next_hop_ilb      = module.ilb-nva-trusted["primary"].forwarding_rule_address
  #   }
  # ]
}


module "dev-spoke0-vpc-fireall-rules" {
  source       = "terraform-google-modules/network/google//modules/firewall-rules"
  version      = "~> 7.2"
  project_id   = module.dev-spoke-project.project_id
  network_name = module.dev-spoke-vpc.network_self_link
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


# --------------------------------------------------------------------
# Spoke 0 Dev
# Test Resources
# --------------------------------------------------------------------

module "test-vm-dev-spoke-vnet-primary-0" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/compute-vm?ref=v27.0.0"
  project_id = module.dev-spoke-project.project_id
  zone       = "${var.regions.primary}-b"
  name       = "spoke0-vnet-pri-0"
  network_interfaces = [{
    network    = module.dev-spoke-vpc.network_self_link
    subnetwork = module.dev-spoke-vpc.subnets_self_links[0]
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
# Spoke 0 Dev
# VPC Peering to Hub-Trusted VPC
# --------------------------------------------------------------------

module "peering-dev" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc-peering?ref=v27.0.0"
  prefix        = "dev-peering-0"
  local_network = module.dev-spoke-vpc.network_self_link
  peer_network  = module.landing-trusted-vpc.network_self_link
}