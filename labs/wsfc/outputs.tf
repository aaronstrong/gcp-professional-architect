output "cluster_account" {
  description = "The Acitve Directory account for cluster setup"
  value       = var.cluster_username
}

output "private_addresses" {
  description = "List of private addresses and assigned instances"
  value = {
    for key, addr in google_compute_address.main :
    key => addr.address
  }
}

output "public_ip_active_directory" {
  description = "The public ip assigned to the active directory instance"
  value       = google_compute_instance.dc-1.network_interface.0.access_config.0.nat_ip
}