# -------------------------------------------------------------------
# DEPLOY Service Account to Project
# This script creates a custom role and a service account to be used by FortiGate instances
# -------------------------------------------------------------------

resource "google_service_account" "fortigate_sa" {
  project      = var.project_id
  account_id   = "fortigatesdn-ro"
  display_name = "FortiGate SDN Connector"
}

resource "google_project_iam_binding" "fortigate_sa_iam" {
  for_each = toset(["roles/compute.networkViewer", "roles/container.clusterViewer", "roles/container.viewer"])
  project  = var.project_id
  role     = each.value

  members = [
    google_service_account.fortigate_sa.member,
  ]
}

# Create new random API key to be provisioned in FortiGates.
resource "random_string" "api_key" {
  length  = 30
  special = false
  numeric = true
}

# -------------------------------------------------------------------
# DEPLOY Cloud Storage to Project
# This bucket is used to upload the VM deployment file
# -------------------------------------------------------------------

resource "random_id" "id" {
  byte_length = 2
}

resource "google_storage_bucket" "fortigate_upload" {
  project       = var.project_id
  name          = "fortigate-image-upload-${lower(random_id.id.id)}"
  location      = var.regions.primary
  storage_class = "REGIONAL"

  uniform_bucket_level_access = true

  force_destroy = true
}

resource "google_storage_bucket_object" "fortigate_image" {
  name   = "FGT_VM64_GCP-v7.4.1.F-build2463-FORTINET.out.gcp.tar.gz"
  bucket = google_storage_bucket.fortigate_upload.name
  source = var.image_source_path
}

# -------------------------------------------------------------------
# DEPLOY Compute Image to Project
# Create an image from the uploaded fortigate .tar file and deploy VM
# -------------------------------------------------------------------

resource "google_compute_image" "fortigate_compute_image" {
  project = var.project_id
  name    = "fortigate-image001"

  raw_disk {
    source = format("https://storage.googleapis.com/%s/%s", google_storage_bucket.fortigate_upload.name, google_storage_bucket_object.fortigate_image.name)
  }

  storage_locations = ["${var.regions.primary}"]
}

resource "google_compute_instance" "fortigate_compute_instance" {
  count = var.fgw_count != 0 ? var.fgw_count : 0

  project        = var.project_id
  name           = "fortigate-fw-${var.regions.primary}-${count.index}"
  machine_type   = "custom-1-2048" # VM instance can only have 1 vCPU and 2GB of RAM to use trial licnese
  can_ip_forward = true
  zone           = "${var.regions.primary}-a"
  tags           = ["fortigate"]

  allow_stopping_for_update = true # Allows Terraform to stop and start instance when new configs (like different hardware) are needed

  scheduling {
    preemptible        = true
    automatic_restart  = false
    provisioning_model = "SPOT"
  }

  metadata = {
    #user-data = (count.index == 0 ? local.config_active : 0)
    serial-port-enable = true
  }

  boot_disk {
    auto_delete = true
    initialize_params {
      size  = "10"
      image = google_compute_image.fortigate_compute_image.self_link
    }
  }

  service_account {
    email  = google_service_account.fortigate_sa.email
    scopes = ["cloud-platform"]
  }

  network_interface {
    network_ip = google_compute_address.ext_priv[count.index].address
    subnetwork = module.landing-untrusted-vpc.subnets["${var.regions.primary}/landing-untrusted-default-${local.region_shortnames[var.regions.primary]}"].self_link
    access_config {
      // Static public ip
      nat_ip = google_compute_address.ext_ip[count.index].address
    }
  }

  network_interface {
    network_ip = google_compute_address.int_priv[count.index].address
    subnetwork = module.landing-trusted-vpc.subnets["${var.regions.primary}/landing-trusted-default-${local.region_shortnames[var.regions.primary]}"].self_link
  }
}

# -------------------------------------------------------------------
# Fortigate UMIG
# -------------------------------------------------------------------

resource "google_compute_instance_group" "fgt-umigs" {
  count = var.fgw_count != 0 ? 1 : 0

  project   = var.project_id
  name      = "ftg-umig${count.index}-${var.regions.primary}-${count.index}"
  zone      = google_compute_instance.fortigate_compute_instance[count.index].zone
  instances = [google_compute_instance.fortigate_compute_instance[count.index].self_link]
}

# -------------------------------------------------------------------
# Fortigate Load Balancer and Custom Route
# -------------------------------------------------------------------

module "ftg-mgmt-ilb" {
  count = var.fgw_count != 0 ? 1 : 0

  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-lb-int?ref=v28.0.0"
  project_id    = var.project_id
  region        = var.regions.primary
  name          = "ilb-fortigate"
  service_label = "ilb-fortigate"
  vpc_config = {
    network    = module.landing-trusted-vpc.network_self_link
    subnetwork = module.landing-trusted-vpc.subnets["${var.regions.primary}/landing-trusted-default-uc1"].self_link
  }
  backends = [{
    group = google_compute_instance_group.fgt-umigs[0].self_link
  }]
  health_check_config = {
    http = {
      port = var.healthcheck_port
    }
  }
}

resource "google_compute_route" "ilb-default-route-primary" {
  count = var.fgw_count != 0 ? 1 : 0

  project      = var.project_id
  name         = "${var.regions.primary}rt-default-via-fgt"
  dest_range   = "0.0.0.0/0"
  network      = module.landing-trusted-vpc.network_self_link
  next_hop_ilb = module.ftg-mgmt-ilb[0].id[""]
  priority     = "800"
}

# -------------------------------------------------------------------
# Fortigate Template
# -------------------------------------------------------------------

locals {
  config_active = templatefile("${path.module}/fortigate-config.tpl", {
    hostname         = "${var.prefix}fgtvm-uc1"
    healthcheck_port = var.healthcheck_port
    api_key          = random_string.api_key.result
    ext_ip           = var.fgw_count != 0 ? google_compute_address.ext_ip[0].address : "empty"
    ext_gw           = module.landing-untrusted-vpc.subnets["${var.regions.primary}/landing-untrusted-default-uc1"].gateway_address
    int_ip           = var.fgw_count != 0 ? google_compute_address.int_priv[0].address : "empty"
    int_gw           = module.landing-trusted-vpc.subnets["${var.regions.primary}/landing-trusted-default-uc1"].gateway_address
    int_cidr         = module.landing-trusted-vpc.subnets["${var.regions.primary}/landing-trusted-default-uc1"].ip_cidr_range
    ilb_ip           = var.fgw_count != 0 ? module.ftg-mgmt-ilb[0].forwarding_rule_addresses[""] : "empty"
    api_acl          = var.api_acl
  })
}

resource "local_file" "fortigate-config" {
  content  = local.config_active
  filename = "${path.module}/my-config.yaml"
}