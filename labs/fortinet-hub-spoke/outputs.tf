output "trusted-vpc-firewall-rules" {
  description = "The create firewall rule resources"
  value       = module.landing-trusted-vpc-fireall-rules
}

output "landing_trusted_vpc_full" {
  value = module.landing-trusted-vpc
}

output "fgt_mgmt_eips" {
  value = var.fgw_count != 0 ? google_compute_instance.fortigate_compute_instance[0].network_interface[0].access_config[0].nat_ip : 0
}

output "fgt_password" {
  description = "Fortigate initial password is the instance id"
  value       = var.fgw_count != 0 ? google_compute_instance.fortigate_compute_instance[0].instance_id : 0
}

output "fgt_umigs" {
  value = google_compute_instance_group.fgt-umigs[*].self_link
}

output "api_key" {
  value = random_string.api_key.result
}

output "region" {
  value = var.regions.primary
}

output "prefix" {
  value = var.prefix
}

output "project" {
  value = var.project_id
}

output "ilb" {
  description = "The internal IP of the internal load balancer"
  value       = var.fgw_count != 0 ? module.ftg-mgmt-ilb[0].forwarding_rule_addresses[""] : null
}

output "health_check" {
  value = var.fgw_count != 0 ? tolist(module.ftg-mgmt-ilb[0].backend_service.health_checks)[0] : null
}

output "healthcheck_port" {
  value = var.healthcheck_port
}

output "internal_vpc" {
  value = module.landing-trusted-vpc.subnets["us-central1/landing-trusted-default-uc1"].network
}

output "internal_subnet" {
  value = module.landing-trusted-vpc.subnets["us-central1/landing-trusted-default-uc1"].self_link
}


# -------------------------------------------------------------------
# Fortigate Outputs
# -------------------------------------------------------------------

output "untrust_int_ip" {
  value = var.fgw_count != 0 ? google_compute_instance.fortigate_compute_instance[0].network_interface[0].network_ip : 0
}

output "untrust_int_gw" {
  value = module.landing-untrusted-vpc.subnets["us-central1/landing-untrusted-default-uc1"].gateway_address
}

output "untrust_int_cidr" {
  value = module.landing-untrusted-vpc.subnets["us-central1/landing-untrusted-default-uc1"].ip_cidr_range
}

output "trust_int_ip" {
  value = var.fgw_count != 0 ? google_compute_instance.fortigate_compute_instance[0].network_interface[1].network_ip : 0
}

output "trust_int_gw" {
  value = module.landing-trusted-vpc.subnets["us-central1/landing-trusted-default-uc1"].gateway_address
}

output "trust_int_cidr" {
  value = module.landing-trusted-vpc.subnets["us-central1/landing-trusted-default-uc1"].ip_cidr_range
}

# output "config_active" {
#   value = local.config_active
# }