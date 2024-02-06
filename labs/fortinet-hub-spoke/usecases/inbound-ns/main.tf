locals {
  day0 = data.terraform_remote_state.base.outputs
}

resource "fortios_firewall_policy" "trusted-to-untrusted" {
  // Allow traffic coming from the port 2 (trusted interface) to the port 1 (untrusted interface)
  name            = "trusted-to-untrusted"
  action          = "accept"
  inspection_mode = "flow"
  status          = "enable"
  schedule        = "always"
  ips_sensor      = "default"
  logtraffic      = "all"

  srcintf {
    name = "port2"
  }
  dstintf {
    name = "port1"
  }
  srcaddr {
    name = "all"
  }
  dstaddr {
    name = "all"
  }
  service {
    name = "ALL"
  }

  nat = "enable" // Enable SNAT
}

resource "google_compute_address" "elb_eip" {
  count   = var.toggle_webserver == true ? 1 : 0
  project = local.day0.project
  name    = "${var.srv_name}-eip-${local.day0.region}"
  region  = local.day0.region
}

resource "google_compute_forwarding_rule" "elb_frule" {
  count                 = var.toggle_webserver == true ? 1 : 0
  project               = local.day0.project
  name                  = "${var.srv_name}-fwdrule"
  region                = local.day0.region
  ip_address            = google_compute_address.elb_eip[count.index].self_link
  ip_protocol           = "L3_DEFAULT"
  all_ports             = true
  load_balancing_scheme = "EXTERNAL"
  backend_service       = google_compute_region_backend_service.elb_bes[count.index].self_link
}

resource "google_compute_region_health_check" "default" {
  project            = local.day0.project
  name               = "elb-hc"
  check_interval_sec = 1
  timeout_sec        = 1


  tcp_health_check {
    port = local.day0.healthcheck_port
  }

  region = local.day0.region

}

resource "google_compute_region_backend_service" "elb_bes" {
  count                 = var.toggle_webserver == true ? 1 : 0
  provider              = google-beta
  project               = local.day0.project
  name                  = "${local.day0.prefix}bes-elb-${local.day0.region}"
  region                = local.day0.region
  load_balancing_scheme = "EXTERNAL"
  protocol              = "UNSPECIFIED"

  backend {
    group = local.day0.fgt_umigs[0]
  }

  health_checks = [google_compute_region_health_check.default.id]
  connection_tracking_policy {
    connection_persistence_on_unhealthy_backends = "NEVER_PERSIST"
  }
}

# configure probes
# Note that we need to use the loopback interface so the use-case terraform_version
# configuration is destroyable (not possible if we used secondary ip)
data "fortios_system_interface" "probe" {
  name = "probe"
}
data "fortios_system_proberesponse" "probe" {}

resource "fortios_firewall_vip" "vip_probe" {
  name        = "${var.srv_name}-probe"
  extintf     = "port1"
  extip       = google_compute_address.elb_eip[0].address
  portforward = "enable"
  extport     = data.fortios_system_proberesponse.probe.port
  mappedport  = data.fortios_system_proberesponse.probe.port
  mappedip {
    range = split(" ", data.fortios_system_interface.probe.ip)[0]
  }
}

resource "fortios_firewallservice_custom" "service_probe" {
  name          = "LB_Probe"
  tcp_portrange = data.fortios_system_proberesponse.probe.port
}

resource "fortios_firewall_policy" "probe_allow" {
  name            = "allow-${var.srv_name}-probe"
  action          = "accept"
  schedule        = "always"
  inspection_mode = "flow"
  status          = "enable"

  srcintf {
    name = "port1"
  }
  dstintf {
    name = "probe"
  }
  srcaddr {
    name = "all"
  }
  dstaddr {
    name = fortios_firewall_vip.vip_probe.name
  }
  service {
    name = fortios_firewallservice_custom.service_probe.name
  }
  nat = "disable"
}

# Forwarding the N-S traffic
resource "fortios_firewall_vip" "vip" {
  count = length(var.targets)

  name        = "${var.srv_name}-tcp${var.targets[count.index].port}"
  extintf     = "port1"
  extip       = google_compute_address.elb_eip[0].address
  portforward = "enable"
  extport     = var.targets[count.index].port
  mappedport  = var.targets[count.index].mappedport

  mappedip {
    range = var.targets[count.index].ip
  }
}

resource "fortios_firewallservice_custom" "service" {
  count = length(var.targets)

  name          = "${var.srv_name}-tcp${var.targets[count.index].mappedport}"
  tcp_portrange = var.targets[count.index].mappedport
}

resource "fortios_firewall_policy" "vip_allow" {
  count = length(var.targets)

  name            = "allow-${var.srv_name}-tcp${var.targets[count.index].port}"
  action          = "accept"
  schedule        = "always"
  inspection_mode = "flow"
  status          = "enable"
  logtraffic      = var.logtraffic

  srcintf {
    name = "port1"
  }
  dstintf {
    name = "port2"
  }
  srcaddr {
    name = "all"
  }
  dstaddr {
    name = fortios_firewall_vip.vip[count.index].name
  }
  service {
    name = fortios_firewallservice_custom.service[count.index].name
  }
  nat = "disable"
}


# -----------------------------------------------------
# Variables
# -----------------------------------------------------

variable "srv_name" {
  type        = string
  description = "Name of the service to be created. It will be used as part of resource names."
  default     = "web"
}

variable "targets" {
  type = list(object({
    ip         = string
    port       = number
    mappedport = number
  }))
  description = "List of target IP and port tuples for creating DNATs on FortiGate."
  default = [
    {
      ip         = "10.68.24.2",
      port       = 80,
      mappedport = 8080
    },
  ]
}

variable "logtraffic" {
  type        = string
  default     = "all"
  description = "logtraffic value to relay to fortios_firewall_policy resource"
}