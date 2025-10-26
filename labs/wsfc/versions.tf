terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.2.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "7.2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
}