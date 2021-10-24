output "ilb_address" {
  description = "TCP Internal load balancer address."
  value       = google_compute_forwarding_rule.google_compute_forwarding_rule.ip_address
}