# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables are expected to be passed in by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "peer_ips" {
  description = "External IP address"
  type        = list(string)
}

variable "remote_subnet" {
  description = "The subnets at the remote location. Use the on-premises CIDR."
  type        = list(string)
  default     = ["192.168.0.0/16"]
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "environment" {
  description = "Environment"
  type        = string
  default     = "test"
}

variable "api_services" {
  description = "What APIs services are available"
  type        = list(string)
  default     = ["dns.googleapis.com"]
}

variable "region" {
  description = "The GCP region to deploy resources."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone to deploy resources into."
  type        = string
  default     = "us-central1-b"
}

variable "shared_secret" {
  description = "The shared secret between tunnels."
  type        = string
  default     = "mySecret"
}

variable "preemptible" {
  description = "Set if this instance should be preemptible"
  type        = bool
  default     = true
}

variable "auto_restart" {
  description = "Set if the instance should auto-restart."
  type        = bool
  default     = false
}

variable "boot_disk" {
  description = "What image the instance should boot from."
  type        = string
  default     = "windows-cloud/windows-2022"
}

variable "static_ip" {
  description = "The last octet in a static host ip address."
  type        = number
  default     = 10
}

variable "prefix_hostname" {
  description = "The hostname prefix"
  type        = string
  default     = "claddc"
}

variable "dc_machine_type" {
  description = "Machine type to deploy for the Domain Controller"
  type        = string
  default     = "e2-medium"
}