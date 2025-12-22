module "vpc_subnet_01" {
  source  = "cloudposse/label/null"
  version = "~> 0.25"
  # Default order is `namespace`, `environment`, `stage`, `name`, `attributes`.
  # Override with `label_order`

  # {company}-{app or BU}-{region}

  namespace           = "us-central1"
  environment         = var.environment
  stage               = ""
  name                = "subnet"
  attributes          = ["01"]
  delimiter           = "-"
  id_length_limit     = 63
  label_key_case      = "lower"
  enabled             = true
  regex_replace_chars = "/[^a-zA-Z0-9-+]/"
}

# module "vpc_subnet_02" {
#   source  = "cloudposse/label/null"
#   version = "~> 0.25"
#   # Default order is `namespace`, `environment`, `stage`, `name`, `attributes`.
#   # Override with `label_order`

#   # {company}-{app or BU}-{region}

#   namespace           = "us-east1"
#   environment         = var.environment
#   stage               = ""
#   name                = "subnet"
#   attributes          = ["02"]
#   delimiter           = "-"
#   id_length_limit     = 63
#   label_key_case      = "lower"
#   enabled             = true
#   regex_replace_chars = "/[^a-zA-Z0-9-+]/"
# }

module "vpc_hub" {
  source  = "cloudposse/label/null"
  version = "~> 0.25"
  # Default order is `namespace`, `environment`, `stage`, `name`, `attributes`.
  # Override with `label_order`

  # {company}-{app or BU}-{region}

  namespace           = "vpc"
  environment         = var.environment
  stage               = ""
  name                = "hub"
  attributes          = ["01"]
  delimiter           = "-"
  id_length_limit     = 63
  label_key_case      = "lower"
  enabled             = true
  regex_replace_chars = "/[^a-zA-Z0-9-+]/"
}

module "fw_iap_allow" {
  source  = "cloudposse/label/null"
  version = "~> 0.25"
  # Default order is `namespace`, `environment`, `stage`, `name`, `attributes`.
  # Override with `label_order`
  # {company}-{description}-{destination}-{protocol}-{port}-{action}

  namespace   = "fw"
  environment = var.environment
  stage       = "allow"
  name        = "iap"
  #attributes          = [""]
  delimiter           = "-"
  id_length_limit     = 63
  label_key_case      = "lower"
  enabled             = true
  regex_replace_chars = "/[^a-zA-Z0-9-+]/"
}

module "fw_dc_allow" {
  source  = "cloudposse/label/null"
  version = "~> 0.25"
  # Default order is `namespace`, `environment`, `stage`, `name`, `attributes`.
  # Override with `label_order`
  # {company}-{description}-{destination}-{protocol}-{port}-{action}

  namespace   = "fw"
  environment = var.environment
  stage       = "allow"
  name        = "dc"
  #attributes          = [""]
  delimiter           = "-"
  id_length_limit     = 63
  label_key_case      = "lower"
  enabled             = true
  regex_replace_chars = "/[^a-zA-Z0-9-+]/"
}

module "fw_dns_allow" {
  source  = "cloudposse/label/null"
  version = "~> 0.25"
  # Default order is `namespace`, `environment`, `stage`, `name`, `attributes`.
  # Override with `label_order`
  # {company}-{description}-{destination}-{protocol}-{port}-{action}

  namespace   = "fw"
  environment = var.environment
  stage       = "allow"
  name        = "dns"
  #attributes          = [""]
  delimiter           = "-"
  id_length_limit     = 63
  label_key_case      = "lower"
  enabled             = true
  regex_replace_chars = "/[^a-zA-Z0-9-+]/"
}

module "gce_dc_one" {
  source  = "cloudposse/label/null"
  version = "~> 0.25"
  # Default order is `namespace`, `environment`, `stage`, `name`, `attributes`.
  # Override with `label_order`

  namespace   = ""
  environment = var.environment
  #stage               = "us-c1"
  name                = "dc"
  attributes          = ["01"]
  delimiter           = "-"
  id_length_limit     = 15
  label_key_case      = "lower"
  enabled             = true
  regex_replace_chars = "/[^a-zA-Z0-9-+]/"

  tags = {
    "owner"       = "dc"
    "application" = "active_directory"
  }
}

# module "gce_dc_two" {
#   source  = "cloudposse/label/null"
#   version = "~> 0.25"
#   # Default order is `namespace`, `environment`, `stage`, `name`, `attributes`.
#   # Override with `label_order`

#   namespace   = ""
#   environment = var.environment
#   #stage               = "us-e1"
#   name                = "dc"
#   attributes          = ["02"]
#   delimiter           = "-"
#   id_length_limit     = 15
#   label_key_case      = "lower"
#   enabled             = true
#   regex_replace_chars = "/[^a-zA-Z0-9-+]/"

#   tags = {
#     "owner"       = "dc"
#     "application" = "active_directory"
#   }
# }

# module "gce_test" {
#   source  = "cloudposse/label/null"
#   version = "~> 0.25"
#   # Default order is `namespace`, `environment`, `stage`, `name`, `attributes`.
#   # Override with `label_order`

#   namespace   = ""
#   environment = var.environment
#   #stage               = "us-central1"
#   name                = "instance"
#   attributes          = ["01"]
#   delimiter           = "-"
#   id_length_limit     = 15
#   label_key_case      = "lower"
#   enabled             = true
#   regex_replace_chars = "/[^a-zA-Z0-9-+]/"
# }