locals {
  regions = distinct(concat(
    values(var.regions),
    # values(module.landing-trusted-vpc.subnet_regions),
    # values(module.landing-untrusted-vpc.subnet_regions),
  ))
  # only map when the first character would not work
  _region_cardinal = {
    southeast = "se"
  }
  # only map when the first character would not work
  _region_geo = {
    australia = "o"
  }
  # split in [geo, cardinal, number] tokens
  _region_tokens = {
    for v in local.regions : v => regexall("(?:[a-z]+)|(?:[0-9]+)", v)
  }
  region_shortnames = {
    for k, v in local._region_tokens : k => join("", [
      # first token via geo alias map or first character
      lookup(local._region_geo, v.0, substr(v.0, 0, 1)),
      # first token via cardinal alias map or first character
      lookup(local._region_cardinal, v.1, substr(v.1, 0, 1)),
      # region number as is
      v.2
    ])
  }
}



# -------------------------------------------------------------------
# DEPLOY APIs to Project
# -------------------------------------------------------------------

resource "google_project_service" "project" {
  for_each                   = toset(var.api_services)
  project                    = var.project_id
  service                    = each.value
  disable_dependent_services = true
}