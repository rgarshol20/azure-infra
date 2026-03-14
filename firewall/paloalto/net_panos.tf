# ===============================
# PAN-OS Terraform Configuration
# ===============================

provider "panos" {
  hostname = "ddepan.acme-health.com"
  username = "test-admin"
  password = var.admin_password
}

resource "panos_template" "main" {
  location = { panorama = {} }
  name     = "acme-health-template"
}

resource "panos_device_group" "main" {
  location = { panorama = {} }
  name     = "acme-health-dg"
}

resource "panos_template_stack" "main" {
  location = { panorama = {} }
  name     = "acme-health-stack"
  templates = [
    panos_template.main.name
  ]
  # default_vsys = "vsys1"
  # devices = [var.firewall_serial_number]
}

resource "panos_dns_settings" "umbrella" {
  location = { system = {} }

  dns_settings = {
    servers = {
      primary   = "208.67.222.222"
      secondary = "208.67.220.220"
    }
  }
}

resource "panos_ethernet_interface" "untrust" {
  name = "ethernet1/1"
  location = {
    template = {
      name = panos_template.main.name
      vsys = "vsys1"
    }
  }
  comment = "Untrust zone interface"
  layer3 = {
    dhcp_client = {}
  }
}

resource "panos_ethernet_interface" "trust" {
  name = "ethernet1/2"
  location = {
    template = {
      name = panos_template.main.name
      vsys = "vsys1"
    }
  }
  comment = "Trust zone interface"
  layer3 = {
    dhcp_client = {}
  }
}

resource "panos_ethernet_interface" "dmz" {
  name = "ethernet1/3"
  location = {
    template = {
      name = panos_template.main.name
      vsys = "vsys1"
    }
  }
  comment = "DMZ zone interface"
  layer3 = {
    dhcp_client = {}
  }
}

resource "panos_tunnel_interface" "tunnel1" {
  location = {
    template = {
      name = panos_template.main.name
      vsys = "vsys1"
    }
  }

  name = "tunnel.1"

  comment = "AHDS Tunnel Interface"
  mtu     = 1500

  ip = [
    { name = "100.64.203.46/32" }
  ]
}
resource "panos_zone" "vpn" {
  location = {
    template = {
      name = panos_template.main.name
      vsys = "vsys1"
    }
  }

  name = "VPN"

  network = {
    layer3 = ["tunnel.1"]
  }
}

resource "panos_zone" "trust" {
  location = {
    template = {
      name = panos_template.main.name
      vsys = "vsys1"
    }
  }

  name = "Trust"
  # enable_device_identification = true
  # enable_user_identification   = true

  network = {
    layer3                          = ["ethernet1/2"]
    enable_packet_buffer_protection = true
  }
}

resource "panos_zone" "untrust" {
  location = {
    template = {
      name = panos_template.main.name
      vsys = "vsys1"
    }
  }

  name = "Untrust"
  # enable_device_identification = true
  # enable_user_identification   = true

  network = {
    layer3                          = ["ethernet1/1"]
    enable_packet_buffer_protection = true
  }
}

resource "panos_zone" "dmz" {
  location = {
    template = {
      name = panos_template.main.name
      vsys = "vsys1"
    }
  }

  name = "DMZ"
  # enable_device_identification = true
  # enable_user_identification   = true

  network = {
    layer3                          = ["ethernet1/3"]
    enable_packet_buffer_protection = true
  }
}

resource "panos_virtual_router" "default" {
  location = {
    template = {
      name = panos_template.main.name
      vsys = "vsys1"
    }
  }

  name = "default"

  interfaces = [
    panos_ethernet_interface.trust.name,
    panos_ethernet_interface.untrust.name,
    panos_ethernet_interface.dmz.name,
    panos_tunnel_interface.tunnel1.name
  ]
}

resource "panos_virtual_router_static_routes_ipv4" "internet" {
  location = {
    template = {
      name = panos_template.main.name
      vsys = "vsys1"
    }
  }
  virtual_router = panos_virtual_router.default.name
  static_routes = [{
    name        = "internet-route"
    destination = "0.0.0.0/0"
    interface   = panos_ethernet_interface.untrust.name
    nexthop = {
      ip_address = "10.99.1.1"
    }
  }]
}

resource "panos_virtual_router_static_routes_ipv4" "ahds" {
  location = {
    template = {
      name = panos_template.main.name
      vsys = "vsys1"
    }
  }
  virtual_router = panos_virtual_router.default.name
  static_routes = [{
    name        = "ahds-route"
    destination = "100.64.47.0/24"
    interface   = panos_tunnel_interface.tunnel1.name
  }]
}

resource "panos_virtual_router_static_routes_ipv4" "ad" {
  location = {
    template = {
      name = panos_template.main.name
      vsys = "vsys1"
    }
  }
  virtual_router = panos_virtual_router.default.name
  static_routes = [{
    name        = "ad-route"
    destination = "10.99.4.0/24"
    interface   = panos_ethernet_interface.trust.name
    nexthop = {
      ip_address = "10.99.2.1"
    }
  }]
}


resource "panos_virtual_router_static_routes_ipv4" "twingate" {
  location = {
    template = {
      name = panos_template.main.name
      vsys = "vsys1"
    }
  }
  virtual_router = panos_virtual_router.default.name
  static_routes = [{
    name        = "twingate-route"
    destination = "10.99.5.0/24"
    interface   = panos_ethernet_interface.trust.name
    nexthop = {
      ip_address = "10.99.2.1"
    }
  }]
}

resource "panos_virtual_router_static_routes_ipv4" "billings" {
  location = {
    template = {
      name = panos_template.main.name
      vsys = "vsys1"
    }
  }
  virtual_router = panos_virtual_router.default.name
  static_routes = [{
    name        = "billings-route"
    destination = "10.50.0.0/16"
    interface   = panos_ethernet_interface.trust.name
    nexthop = {
      ip_address = "10.99.2.1"
    }
  }]
}