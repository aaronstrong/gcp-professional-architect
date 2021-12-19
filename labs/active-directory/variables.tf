# -------------------------------------------------------------------
# REQUIRED VARIABLES
# -------------------------------------------------------------------

variable "project_id" {
  description = "The project ID"
  type        = string
}

# -------------------------------------------------------------------
# OPTIONAL VARIABLES
# -------------------------------------------------------------------

variable "region" {
  type    = string
  default = "us-central1"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "test"
}

variable "cidr_prefix" {
  description = "Must be given in CIDR notation. The assigned supernet."
  type        = string
  default     = "10.0.0.0/15"
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
  default     = "windows-cloud/windows-2019"
}

variable "static_ip" {
  description = "The last octet in a static host ip address."
  type        = number
  default     = 2
}

variable "prefix_hostname" {
  description = "The hostname prefix"
  type        = string
  default     = "addc"
}

variable "dc_machine_type" {
  description = "Machine type to deploy for the Domain Controller"
  type        = string
  default     = "e2-medium"
}