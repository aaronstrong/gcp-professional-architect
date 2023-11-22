# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables are expected to be passed in by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "project_id" {
  description = "Project ID"
  type        = string
}

variable "prefix" {
  # tfdoc:variable:source 0-bootstrap
  description = "Prefix used for resources that need unique names. Use 9 characters or less."
  type        = string
  default = "test"

  validation {
    condition     = try(length(var.prefix), 0) < 10
    error_message = "Use a maximum of 9 characters for prefix."
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "api_services" {
  description = "What APIs services are available"
  type        = list(string)
  default     = ["dns.googleapis.com", "compute.googleapis.com", "iap.googleapis.com", "networkmanagement.googleapis.com", "stackdriver.googleapis.com"]
}

variable "gcp_ranges" {
  description = "GCP address ranges in name => range format."
  type        = map(string)
  default = {
    gcp_dev_primary                 = "10.68.0.0/16"
    gcp_dev_secondary               = "10.84.0.0/16"
    gcp_landing_trusted_primary     = "10.64.0.0/17"
    gcp_landing_trusted_secondary   = "10.80.0.0/17"
    gcp_landing_untrusted_primary   = "10.64.127.0/17"
    gcp_landing_untrusted_secondary = "10.80.127.0/17"
    gcp_prod_primary                = "10.72.0.0/16"
    gcp_prod_secondary              = "10.88.0.0/16"
  }
}

variable "regions" {
  description = "Region definitions."
  type = object({
    primary   = string
    secondary = string
  })
  default = {
    primary   = "us-central1"
    secondary = "us-east1"
  }
}