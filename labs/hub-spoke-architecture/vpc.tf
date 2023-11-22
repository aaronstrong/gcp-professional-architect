module "landing-trusted-vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 8.0"

  project_id   = var.project_id
  network_name = "vpc-landing-trusted-0"
  routing_mode = "GLOBAL"

  delete_default_internet_gateway_routes = false
  shared_vpc_host                        = true

  subnets = [
    {
      subnet_name           = "landing-trusted-default-uc1"
      subnet_ip             = "10.64.0.0/24"
      subnet_region         = "us-central1"
      subnet_private_access = "true"
      subnet_flow_logs      = "false"
      description           = "This subnet has a description"
    },
    {
      subnet_name           = "landing-trusted-default-ue1"
      subnet_ip             = "10.80.0.0/24"
      subnet_region         = "us-east1"
      subnet_private_access = "true"
      subnet_flow_logs      = "false"
      description           = "This subnet has a description"
    }
  ]

  depends_on = [google_project_service.project]
}


module "landing-trusted-vpc-fireall-rules" {
  source       = "terraform-google-modules/network/google//modules/firewall-rules"
  version      = "~> 7.2"
  project_id   = var.project_id
  network_name = module.landing-trusted-vpc.network_name
  rules = [
    {
      name          = "allow-hc-nva-ssh-trusted"
      description   = "Allow traffic from Google healthchecks to NVA appliances"
      direction     = "INGRESS"
      priority      = null
      source_ranges = ["35.191.0.0/16", "130.211.0.0/22", "209.85.152.0/22", "209.85.204.0/22"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["22"]
        }
      ]
    }
  ]
}

module "landing-untrusted-vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 8.0"

  project_id   = var.project_id
  network_name = "vpc-landing-untrusted-0"
  routing_mode = "GLOBAL"

  delete_default_internet_gateway_routes = false
  shared_vpc_host                        = false

  subnets = [
    {
      subnet_name           = "landing-untrusted-default-uc1"
      subnet_ip             = "10.64.128.0/24"
      subnet_region         = "us-central1"
      subnet_private_access = "true"
      subnet_flow_logs      = "false"
      description           = "This subnet has a description"
    },
    {
      subnet_name           = "landing-untrusted-default-ue1"
      subnet_ip             = "10.80.128.0/24"
      subnet_region         = "us-east1"
      subnet_private_access = "true"
      subnet_flow_logs      = "false"
      description           = "This subnet has a description"
    }
  ]

  depends_on = [google_project_service.project]
}

module "landing-untrusted-vpc-fireall-rules" {
  source       = "terraform-google-modules/network/google//modules/firewall-rules"
  version      = "~> 7.2"
  project_id   = var.project_id
  network_name = module.landing-untrusted-vpc.network_name
  rules = [
    {
      name          = "allow-hc-nva-ssh-untrusted"
      description   = "Allow traffic from Google healthchecks to NVA appliances"
      direction     = "INGRESS"
      priority      = null
      source_ranges = ["35.191.0.0/16", "130.211.0.0/22", "209.85.152.0/22", "209.85.204.0/22"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["22"]
        }
      ]
    }
  ]
}