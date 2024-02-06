module "spoke1" {
  // Create a Spoke GCP project with a VPC, Firewall rules and VPC peer back to the Hub
  source = "./modules/project-vpc"

  org_id          = "575228741867"
  billing_account = "01EF01-627C10-7CD2DF"
  folder_id       = "87107581794"
  subnets = [
    {
      subnet_name           = "dev-default-uc1"
      subnet_ip             = "10.68.0.0/24"
      subnet_region         = "us-central1"
      description           = "This subnet has a description for dev"
      subnet_private_access = "true"
    },
  ]

  peer_network = trimprefix(local.day0.internal_vpc, "https://www.googleapis.com/compute/v1/")
  prefix       = "spoke1"

  rules = [
    {
      name          = "allow-all-protocols"
      description   = "Allow most popular protocols for testing, managed by Terraform"
      direction     = "INGRESS"
      priority      = null
      source_ranges = ["0.0.0.0/0"]
      allow = [
        {
          protocol = "all"
        }
      ]
    }
  ]
}

variable "toggle_webserver" {
  type    = bool
  default = true
}

resource "google_compute_address" "wrkld_tier2" {
  count        = var.toggle_webserver == true ? 1 : 0
  project      = module.spoke1.project_id
  name         = "${local.day0.prefix}ip-wrkld-tier2"
  region       = local.day0.region
  address_type = "INTERNAL"
  subnetwork   = module.spoke1.subnets_ids[0]
}


resource "google_compute_instance" "wrkld_websrv" {
  count        = var.toggle_webserver == true ? 1 : 0
  project      = module.spoke1.project_id
  name         = "${local.day0.prefix}wrkld-tier2-websrv"
  zone         = "${local.day0.region}-b"
  machine_type = "e2-micro"
  tags         = ["tier2"]

  allow_stopping_for_update = true # Allows Terraform to stop and start instance when new configs (like different hardware) are needed

  scheduling {
    preemptible        = true
    automatic_restart  = false
    provisioning_model = "SPOT"
  }

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }
  network_interface {
    subnetwork = module.spoke1.subnets_ids[0]
    network_ip = google_compute_address.wrkld_tier2[count.index].address
  }
  #   depends_on = [
  #     module.peer2,
  #     module.outbound
  #   ]

metadata_startup_script = <<EOT
sudo apt update;
sudo apt -y install nginx
sudo echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > /var/www/html/eicar.com
EOT

}

output "spoke1_project_id" {
  value = module.spoke1.project_id
}

output "spoke1_network_id" {
  value = module.spoke1.network_id
}

output "spoke1_network_name" {
  value = module.spoke1.network_name
}

output "spoke1_network_self_link" {
  value       = module.spoke1.network_self_link
  description = "The URI of the VPC being created"
}

output "spoke1_subnets_ids" {
  value       = module.spoke1.subnets_ips
  description = "The IDs of the subnets being created"
}

output "spoke1_subnets_self_links" {
  value       = module.spoke1.subnets_self_links
  description = "The self-links of subnets being created"
}