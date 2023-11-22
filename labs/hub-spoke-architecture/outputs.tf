
output "trusted-vpc-firewall-rules" {
  description = "The create firewall rule resources"
  value       = module.landing-trusted-vpc-fireall-rules
}

# output "landing-trusted-vpc" {
#   value = module.landing-trusted-vpc
# }

# output "landing-untrusted-vpc" {
#   value = module.landing-untrusted-vpc
# }