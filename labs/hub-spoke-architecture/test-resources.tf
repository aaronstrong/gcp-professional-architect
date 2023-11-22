
# Trusted (hub)

# module "test-vm-landing-trusted-primary-0" {
#   source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/compute-vm"
#   project_id = var.project_id
#   zone       = "${var.regions.primary}-b"
#   name       = "test-vm-lnd-tru-pri-0"
#   network_interfaces = [{
#     network    = module.landing-untrusted-vpc.network_self_link
#     subnetwork = module.landing-trusted-vpc.subnets["${var.regions.primary}/landing-trusted-default-${local.region_shortnames[var.regions.primary]}"].self_link
#   }]
#   tags                   = ["primary", "ssh"]
#   service_account_create = true
#   boot_disk = {
#     initialize_params = {
#         image = "projects/debian-cloud/global/images/family/debian-10"
#     }
#   }
#   options = {
#     spot               = true
#     termination_action = "STOP"
#   }
#   metadata = {
#     startup-script = <<EOF
#       apt update
#       apt install iputils-ping bind9-dnsutils
#     EOF
#   }
# }