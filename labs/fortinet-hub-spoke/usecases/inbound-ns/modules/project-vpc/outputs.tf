// Project Outputs

output "project_name" {
  description = "Name of the project"
  value       = module.project-factory.project_name
}

output "project_id" {
  description = "ID of the project"
  value       = module.project-factory.project_id
}

output "project_number" {
  description = "Numeric identifier for the project"
  value       = module.project-factory.project_number
}

output "enabled_apis" {
  description = "Enabled APIs in the project"
  value       = module.project-factory.enabled_apis
}

// VPC outputs

output "network" {
  value       = module.vpc
  description = "The created network"
}

output "subnets" {
  value       = module.vpc.subnets
  description = "A map with keys of form subnet_region/subnet_name and values being the outputs of the google_compute_subnetwork resources used to create corresponding subnets."
}

output "network_name" {
  value       = module.vpc.network_name
  description = "The name of the VPC being created"
}

output "network_id" {
  value       = module.vpc.network_id
  description = "The ID of the VPC being created"
}

output "network_self_link" {
  value       = module.vpc.network_self_link
  description = "The URI of the VPC being created"
}


output "subnets_ids" {
  value       = [for network in module.vpc.subnets : network.id]
  description = "The IDs of the subnets being created"
}

output "subnets_ips" {
  value       = [for network in module.vpc.subnets : network.ip_cidr_range]
  description = "The IPs and CIDRs of the subnets being created"
}

output "subnets_self_links" {
  value       = [for network in module.vpc.subnets : network.self_link]
  description = "The self-links of subnets being created"
}

output "subnets_regions" {
  value       = [for network in module.vpc.subnets : network.region]
  description = "The region where the subnets will be created"
}

// Fireall Rules Outputs

output "firewall_rules" {
  value       = module.firewall-rules.firewall_rules
  description = "The created firewall rule resources"
}

// VPC Peering Outputs

output "local_network_peering" {
  description = "Network peering resource."
  value       = module.peering.local_network_peering
}

output "peer_network_peering" {
  description = "Peer network peering resource."
  value       = module.peering.peer_network_peering
}