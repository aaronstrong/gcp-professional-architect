# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables are expected to be passed in by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "remote_subnet" {
  description = "The subnets at the remote location. Use the on-premises CIDR."
  type        = list(string)
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

# variable "peer_ips" {
#   description = "External IP address. If empty, auto-detect own IP address."
#   type        = list(string)
#   default     = []
# }

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