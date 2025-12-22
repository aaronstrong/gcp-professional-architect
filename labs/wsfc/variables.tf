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
  description = "The region to deploy resources into."
  type        = string
  default     = "us-central1"
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

variable "dc_machine_type" {
  description = "Machine type to deploy for the Domain Controller"
  type        = string
  default     = "e2-medium"
}

variable "dc_name" {
  description = "Name of the Active Directory Domain Controller"
  type        = string
  default     = "test-dc-01"
}

variable "project_services" {
  description = "API services to enable"
  type        = list(any)
  default = [
    "dns.googleapis.com",
    "secretmanager.googleapis.com",
    "compute.googleapis.com"
  ]
}

variable "default_app_port" {
  description = "WSFC default application port"
  type        = string
  default     = "59998"
}

variable "AdDnsDomain" {
  description = "Active Directory domain (FQDN)"
  type        = string
  default     = "contoso.local"

  validation {
    condition     = length(var.AdDnsDomain) > 0
    error_message = "Active Directory domain needs to be specified."
  }
}

variable "AdNetbiosDomain" {
  description = "Active Directory domain (NetBIOS)"
  type        = string
  default     = "CLOUD"

  validation {
    condition     = length(var.AdNetbiosDomain) > 0
    error_message = "Active Directory domain needs to be specified"
  }
}

variable "cluster_name" {
  description = "Windows server failover cluster name"
  type        = string
  default     = "testcluster"
}

variable "cluster_username" {
  description = "The Active Directory name to be used by the WSFC cluster."
  type        = string
  default     = "cluster-admin"
}

variable "cluster_password" {
  description = "The password used by the default `cluster-admin` Active Diretory"
  type        = string
  default     = "Password1"
}

variable "managed_ad_dn" {
  description = "Managed Active Directory domain (eg. OU=Cloud,DC=example,DC=com)."
  type        = string
  default     = "DC=contoso,DC=local"
}

variable "list_reserved_ips" {
  description = "Map of reserved IPs to be created. Address is the last octet in the CIDR"
  type = map(object({
    name    = string
    address = string

  }))
  default = {
    "wsfc1" = {
      name    = "reserved-wsfc-1"
      address = 4
    }
    "wsfc2" = {
      name    = "reserved-wsfc-2"
      address = 5
    }
    "dc1" = {
      name    = "reserved-addc1"
      address = 6
    }
    "loadbalancer" = {
      name    = "reserved-ilb"
      address = 9
    }
    "cluster_ip" = {
      name    = "reserved-cluster-ip"
      address = 8
    }
  }
}

variable "list_instances" {
  description = "Map of instances and their properties"
  type = map(object({
    name         = string
    machine_type = string
    zone         = string
    preemptible  = string
  }))
  default = {
    "wsfc1" = {
      name         = "wsfc-1"
      machine_type = "e2-standard-2"
      zone         = "b"
      preemptible  = false
    }
    "wsfc2" = {
      name         = "wsfc-2"
      machine_type = "e2-standard-2"
      zone         = "c"
      preemptible  = false
    }
  }
}

variable "secret_id" {
  description = "Name of the Secret. Note: not the actual password"
  type        = string
  default     = "ad-password"
}