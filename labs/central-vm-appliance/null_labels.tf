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