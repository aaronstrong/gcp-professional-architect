module "spoke2" {
  // Create a Spoke GCP project with a VPC, Firewall rules and VPC peer back to the Hub
  source = "./modules/project-vpc"

  org_id          = "575228741867"
  billing_account = "01EF01-627C10-7CD2DF"
  folder_id       = "87107581794"
  subnets = [
    {
      subnet_name           = "dev-default-uc1"
      subnet_ip             = "10.68.24.0/24"
      subnet_region         = "us-central1"
      description           = "This subnet has a description for dev"
      subnet_private_access = "true"
    },
  ]

  peer_network = trimprefix(local.day0.internal_vpc, "https://www.googleapis.com/compute/v1/")
  prefix       = "spoke2"

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

variable "toggle_webproxy" {
  type    = bool
  default = true
}

resource "google_compute_address" "wrkld_proxy" {
  count        = var.toggle_webproxy == true ? 1 : 0
  project      = module.spoke2.project_id
  name         = "${local.day0.prefix}ip-wrkld-proxy"
  region       = local.day0.region
  address_type = "INTERNAL"
  subnetwork   = module.spoke2.subnets_ids[0]
}


resource "google_compute_instance" "wrkld_webproxy" {
  count        = var.toggle_webproxy == true ? 1 : 0
  project      = module.spoke2.project_id
  name         = "${local.day0.prefix}wrkld-proxy-websrv"
  zone         = "${local.day0.region}-b"
  machine_type = "e2-micro"
  tags         = ["proxy"]

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
    subnetwork = module.spoke2.subnets_ids[0]
    network_ip = google_compute_address.wrkld_proxy[count.index].address
  }
  #   depends_on = [
  #     module.peer2,
  #     module.outbound
  #   ]
  #metadata_startup_script = file("./installs/install_proxy.sh")
metadata_startup_script = <<EOT
#! /bin/bash

# Install Nginx
sudo apt-get update 
sudo apt-get install -y nginx

# Create Nginx configuration file
sudo echo
"server {
    listen 8080;
    location / {
    proxy_pass http://${google_compute_address.wrkld_proxy[count.index].address};
    }
}" > /etc/nginx/sites-available/proxy.conf

# Enable the Nginx configuration
sudo ln -s /etc/nginx/sites-available/proxy.conf /etc/nginx/sites-enabled/proxy

# Restart Nginx service
sudo systemctl restart nginx
EOT
}

output "spoke2_project_id" {
  value = module.spoke2.project_id
}

output "spoke2_network_id" {
  value = module.spoke2.network_id
}

output "spoke2_network_name" {
  value = module.spoke2.network_name
}

output "spoke2_network_self_link" {
  value       = module.spoke2.network_self_link
  description = "The URI of the VPC being created"
}

output "spoke2_subnets_ids" {
  value       = module.spoke2.subnets_ips
  description = "The IDs of the subnets being created"
}

output "spoke2_subnets_self_links" {
  value       = module.spoke2.subnets_self_links
  description = "The self-links of subnets being created"
}