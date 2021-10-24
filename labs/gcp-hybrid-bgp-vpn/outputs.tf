output "gateway_self_link" {
  description = "The self-link of the Gateway"
  value       = module.classic_vpn.gateway_self_link
}

output "gateway_ip" {
  description = "The VPN Gateway Public IP"
  value       = module.classic_vpn.gateway_ip
}

output "vpn_tunnels_names-static" {
  description = "The VPN tunnel name is"
  value       = module.classic_vpn.vpn_tunnels_names-static
}

output "ipsec_secret-static" {
  description = "The shared secret is:"
  value       = module.classic_vpn.ipsec_secret-static
}