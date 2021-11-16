# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables are expected to be passed in by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "project_id" {
  # Pass in the project ID that pre-exists
  description = "The Project ID"
  type        = string
}

variable "gcp_credentials" {
  type        = string
  sensitive   = true
  description = "Google Cloud service account credentials"
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "region" {
  # Create a VPC
  description = "VPC region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  # Create a subnet
  description = "VPC Zone"
  type        = string
  default     = "us-central1-b"
}

variable "testvm_count" {
  description = "How many test VMs to deploy."
  type        = number
  default     = 1
}

variable "vm_size_squid" {
  description = "Node instance type"
  type        = string
  default     = "g1-small"
}

variable "tags_squid" {
  default = ["squid"]
}

variable "labels_squid" {
  default = {}
}

variable "squid_install_script_path" {
  description = "The script path to install squid proxy."
  type        = string
  default     = "./installer/squid_install.sh"
}