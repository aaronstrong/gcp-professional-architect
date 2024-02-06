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
  default     = "test"

  validation {
    condition     = try(length(var.prefix), 0) < 10
    error_message = "Use a maximum of 9 characters for prefix."
  }
}

variable "org_id" {
  description = "The organization ID."
  type        = string
  default     = null
}

variable "billing_account" {
  description = "The ID of the billing account to associate this project with"
  type        = string
}

variable "folder_id" {
  description = "The ID of a folder to host this project"
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------------------------------------------------
# TOGGLE PARAMETERS
# ---------------------------------------------------------------------------------------------------------------------

variable "fgw_count" {
  description = "The number of fortigate vms to create. Also used to deploy ILB or not."
  type        = number
  default     = 0
}

variable "enable_cloud_dns" {
  description = "Toggle switch to enable or disable Cloud DNS"
  type        = bool
  default     = true
}

variable "toggle_cloud_vpn" {
  description = "Toggle switch to enable Cloud VPN"
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "api_services" {
  description = "What APIs services are available"
  type        = list(string)
  default     = ["dns.googleapis.com", "compute.googleapis.com", "iap.googleapis.com", "networkmanagement.googleapis.com", "stackdriver.googleapis.com", "container.googleapis.com", ]
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

variable "dns" {
  description = "On-prem DNS resolvers."
  type        = map(list(string))
  default = {
    onprem = ["192.168.2.90"]
  }
}

variable "image_source_path" {
  description = "Source path to where the image is stored"
  type        = string
  default     = "./FGT_VM64_GCP-v7.4.1.F-build2463-FORTINET.out.gcp.tar.gz"
}

variable "admin_acl" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "List of CIDRs allowed to connect to FortiGate management interfaces"
}

variable "api_acl" {
  type        = list(string)
  default     = []
  description = "List of CIDRs allowed to connect to FortiGate API (must not be 0.0.0.0/0)"
}

variable "healthcheck_port" {
  type        = number
  default     = 8008
  description = "Port used for LB health checks"
}

variable "dns_managed_zonename" {
  description = "The DNS name of this managed zone, for instance `example.com.`"
  type        = string
  default     = "contoso.local."
}

variable "dns_assigned_name" {
  description = "User assigned name for this resource. Must be unique within the project."
  type        = string
  default     = "contoso-local"
}

variable "target_name_server_addresses" {
  description = "List of target name servers for forwarding zone."
  default = [
    {
      ipv4_address    = "192.168.2.90",
      forwarding_path = "default"
    }
  ]
  type = list(map(any))
}

// Classic VPN

variable "remote_subnet" {
  description = "The subnets at the remote location. Use the on-premises CIDR."
  type        = list(string)
  default     = ["192.168.0.0/16"]
}

variable "shared_secret" {
  description = "The shared secret between tunnels."
  type        = string
  default     = "mySecret"
}