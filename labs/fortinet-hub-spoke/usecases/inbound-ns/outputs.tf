output "elb_frule" {
  value = google_compute_forwarding_rule.elb_frule[0].self_link
}

output "public_ip" {
  value = google_compute_address.elb_eip[0].address
}