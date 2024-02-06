module "project-factory" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 14.4"

  name                           = var.custom_project_name != "" ? var.custom_project_name : "gcp-prj"
  random_project_id              = true
  org_id                         = var.org_id
  folder_id                      = var.folder_id
  billing_account                = var.billing_account
  activate_apis                  = var.api_services
  enable_shared_vpc_host_project = false
}

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 8.0"

  project_id   = module.project-factory.project_id
  network_name = var.custom_vpc_name != "" ? var.custom_vpc_name : "custom-vpc"
  routing_mode = var.routing_mode

  delete_default_internet_gateway_routes = var.delete_default_internet_gateway_routes

  subnets = var.subnets
  #   subnets = [
  #     {
  #       subnet_name           = "dev-default-uc1"
  #       subnet_ip             = "10.68.0.0/24"
  #       subnet_region         = "us-central1"
  #       description           = "This subnet has a description for dev"
  #       subnet_private_access = "true"
  #     },
  #   ]
}

module "firewall-rules" {
  source       = "terraform-google-modules/network/google//modules/firewall-rules"
  version      = "~> 7.2"
  project_id   = module.project-factory.project_id
  network_name = module.vpc.network_self_link
  rules        = var.rules
  #   rules = [
  #     {
  #       name          = "allow-most-protocol"
  #       description   = "Allow most popular protocols for testing, managed by Terraform"
  #       direction     = "INGRESS"
  #       priority      = null
  #       source_ranges = ["0.0.0.0/0"]
  #       allow = [
  #         {
  #           protocol = "tcp"
  #           ports    = ["22", "80", "443"]
  #         },
  #         {
  #           protocol = "icmp"
  #         }
  #       ]
  #     }
  #   ]
}

module "peering" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc-peering?ref=v27.0.0"
  local_network = module.vpc.network_self_link
  peer_network  = var.peer_network
  prefix        = var.prefix
}