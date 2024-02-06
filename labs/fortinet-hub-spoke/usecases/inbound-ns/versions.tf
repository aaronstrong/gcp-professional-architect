terraform {
  required_providers {
    fortios = {
      source  = "fortinetdev/fortios"
      version = "1.18.1"
    }
    google = {
      source = "hashicorp/google"
    }
    google-beta = {
      source = "hashicorp/google-beta"
    }
  }
}

provider "fortios" {
  # TODO: automatically find which peer is primary at the moment of deployment
  #       for now we just go to he first instance

  hostname = data.terraform_remote_state.base.outputs.fgt_mgmt_eips
  #token    = data.terraform_remote_state.base.outputs.api_key
  insecure = "true"
  username = "admin"
  password = "mysecret"
}

# variable "hostname" {
#  default = "35.225.95.154" 
# }

# variable "token" {
#   default = "Y7HBhmQa45jA9VDIJRP2F5a1XsxfOG"
# }