variable "project_id" {
  description = "The Project ID"
  type        = string
}

variable "region" {
  description = "The region to deploy resources."
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "test"
}

variable "firewalls_count" {
  description = "The total number of firewalls to deploy."
  type        = number
  default     = 2
}

variable "instances_count" {
  description = "The total number of instances to deploy."
  type        = number
  default     = 1
}

variable "cidr_prefix" {
  description = "Must be given in CIDR notation. The assigned supernet."
  type        = string
  default     = "10.0.0.0/15"
}