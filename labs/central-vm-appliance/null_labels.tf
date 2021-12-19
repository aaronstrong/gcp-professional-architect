module "vpc_hub" {
  source  = "cloudposse/label/null"
  version = "~> 0.25"

  namespace   = ""
  stage       = "vpc"
  environment = var.environment
  name        = "hub"
  attributes  = ["public"]
  delimiter   = "-"
}

module "vpc_subnet" {
  source  = "cloudposse/label/null"
  version = "~> 0.25"

  namespace   = ""
  stage       = "vpc"
  environment = var.environment
  name        = "subnet"
  attributes  = ["public"]
  delimiter   = "-"
}

module "pfsense" {
  source  = "cloudposse/label/null"
  version = "~> 0.25"

  namespace           = ""
  stage               = ""
  environment         = var.environment
  name                = "pfsense"
  attributes          = ["vm"]
  delimiter           = "-"
  regex_replace_chars = "/[^a-zA-Z0-9-+]/"
}

module "pfsense_two" {
  source  = "cloudposse/label/null"
  version = "~> 0.25"

  namespace   = ""
  stage       = ""
  environment = var.environment
  name        = "pfsense"
  attributes  = ["vm", "02"]
  delimiter   = "-"
}