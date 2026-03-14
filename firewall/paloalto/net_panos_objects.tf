resource "panos_address" "objects" {
  location = {
    device_group = {
      name = panos_device_group.main.name
    }
  }

  for_each = tomap({
    "AHDS" = {
      description = "AHDS"
      ip_netmask  = "100.64.47.0/24"
    },
    "canonical_ntp1" = {
      description = "canonical_ntp1"
      ip_netmask  = "91.189.91.157"
    },
    "canonical_ntp2" = {
      description = "canonical_ntp2"
      ip_netmask  = "185.125.190.0/24"
    },
    "AcmeHealthSvcs" = {
      description = "AcmeHealthSvcs"
      ip_netmask  = "40.83.192.194"
    },
    "Inetsoft_Dashboard" = {
      description = "Inetsoft Dashboard"
      ip_netmask  = "13.64.106.59"
    },
    "MS_Update" = {
      description = "MS Update"
      ip_netmask  = "13.107.4.50"
    },
    "Palo_Alto_Updates" = {
      description = "Palo Alto Updates"
      fqdn        = "updates.paloaltonetworks.com"
    },
    "Palo_Alto_Updates_Akamai" = {
      description = "Palo Alto Updates Akamai"
      fqdn        = "proditpdownloads.paloaltonetworks.com"
    },
    "TwinGate_Home" = {
      description = "TwinGate_Home"
      ip_netmask  = "34.111.220.252"
    }
    "PUBLICIP" = {
      description = "PUBLICIP"
      ip_netmask  = "4.155.104.150"
    }
  })

  name        = each.key
  description = each.value.description
  ip_netmask  = lookup(each.value, "ip_netmask", null)
  ip_range    = lookup(each.value, "ip_range", null)
  fqdn        = lookup(each.value, "fqdn", null)
}

resource "panos_address_group" "NTP_SERVERS" {
  location = {
    device_group = {
      name = panos_device_group.main.name
    }
  }

  name   = "NTP_SERVERS"
  static = [panos_address.objects["canonical_ntp1"].name, panos_address.objects["canonical_ntp2"].name]
}


resource "panos_address_group" "Updates" {
  location = {
    device_group = {
      name = panos_device_group.main.name
    }
  }

  name   = "Updates"
  static = [panos_address.objects["MS_Update"].name, panos_address.objects["Palo_Alto_Updates"].name, panos_address.objects["Palo_Alto_Updates_Akamai"].name]
}


resource "panos_address_group" "VPN" {
  location = {
    device_group = {
      name = panos_device_group.main.name
    }
  }

  name   = "VPN"
  static = [panos_address.objects["AHDS"].name]
}


resource "panos_service" "DNS_TCP" {
  location = {
    device_group = {
      name = panos_device_group.main.name
    }
  }

  name = "DNS_TCP"

  protocol = {
    tcp = {
      destination_port = "53"
    }
  }
}

resource "panos_service" "DNS_UCP" {
  location = {
    device_group = {
      name = panos_device_group.main.name
    }
  }

  name = "DNS_UCP"

  protocol = {
    udp = {
      destination_port = "53"
    }
  }
}

resource "panos_service" "NTP_TCP" {
  location = {
    device_group = {
      name = panos_device_group.main.name
    }
  }

  name = "NTP_TCP"

  protocol = {
    tcp = {
      destination_port = "123"
    }
  }
}

resource "panos_service" "NTP_UDP" {
  location = {
    device_group = {
      name = panos_device_group.main.name
    }
  }

  name = "NTP_UDP"

  protocol = {
    udp = {
      destination_port = "123"
    }
  }
}

resource "panos_service" "Ping" {
  location = {
    device_group = {
      name = panos_device_group.main.name
    }
  }

  name = "Ping"

  protocol = {
    tcp = {
      destination_port = "0"
    }
  }
}

resource "panos_service" "service_https" {
  location = {
    device_group = {
      name = panos_device_group.main.name
    }
  }

  name = "service-https"

  protocol = {
    tcp = {
      destination_port = "443"
    }
  }
}

resource "panos_service" "service_sftp" {
  location = {
    device_group = {
      name = panos_device_group.main.name
    }
  }

  name = "service-sftp"

  protocol = {
    tcp = {
      destination_port = "22"
    }
  }
}

resource "panos_service" "Twingate_TCP_Ports" {
  location = {
    device_group = {
      name = panos_device_group.main.name
    }
  }

  name = "Twingate_TCP_Ports"

  protocol = {
    tcp = {
      destination_port = "30000-31000"
    }
  }
}

resource "panos_service" "Twingate_UDP_Ports" {
  location = {
    device_group = {
      name = panos_device_group.main.name
    }
  }

  name = "Twingate_UDP_Ports"

  protocol = {
    udp = {
      destination_port = "1-65535"
    }
  }
}

resource "panos_security_profile_group" "Threat_Protection" {
  location = {
    device_group = {
      name = panos_device_group.main.name
    }
  }

  name = "AcmeHealth-Threat-Protection"

  virus             = ["default"]
  spyware           = ["default"]
  vulnerability     = ["default"]
  file_blocking     = ["basic file blocking"]
  wildfire_analysis = ["default"]
}

resource "panos_security_profile_group" "Full_Protection" {
  location = {
    device_group = {
      name = panos_device_group.main.name
    }
  }

  name = "AcmeHealth-Full-Protection"

  virus             = ["default"]
  spyware           = ["strict"]
  vulnerability     = ["strict"]
  file_blocking     = ["strict file blocking"]
  url_filtering     = ["default"]
  wildfire_analysis = ["default"]
}


resource "panos_custom_url_category" "PAN_CORTEX" {
  location = {
    device_group = {
      name = panos_device_group.main.name
    }
  }

  name        = "PAN-CORTEX"
  description = "Custom URL category for Cortex"
  type        = "URL List"

  list = [
    "e477589.xdr.us.paloaltonetworks.com",
    "*.paloaltonetworks.com",
    "panw-xdr-installers-prod-us.storage.googleapis.com",
    "panw-xdr-payloads-prod-us.storage.googleapis.com",
    "global-content-profiles-policy.storage.googleapis.com",
    "panw-xdr-evr-prod-us.storage.googleapis.com",
    "xdr-ova-installers-prod-us.storage.googleapis.com"
  ]
}


resource "panos_custom_url_category" "ms_updates" {
  location = {
    device_group = {
      name = panos_device_group.main.name
    }
  }

  name = "MS_UPDATES"
  type = "URL List"
  list = [
    "dl.delivery.mp.microsoft.com",
    "*.windowsupdate.microsoft.com",
    "*.update.microsoft.com",
    "*.windowsupdate.com",
    "watson.microsoft.com",
    "*.data.microsoft.com",
    "oca.microsoft.com",
    "wustat.windows.com",
    "ntservicepack.microsoft.com",
    "*.akamai.net",
    "*.deploy.static.akamaitechnologies.com"
  ]
}

resource "panos_log_forwarding_profile" "azure" {
  location = {
    device_group = {
      name = panos_device_group.main.name
    }
  }

  name = "Azure"

  match_list = [
    {
      name             = "Threat Logs"
      log_type         = "threat"
      filter           = "All Logs"
      send_to_panorama = true
      http             = ["Azure"]
    },
    {
      name             = "Wildfire Logs"
      log_type         = "wildfire"
      filter           = "All Logs"
      send_to_panorama = true
      http             = ["Azure"]
    },
    {
      name             = "Auth Logs"
      log_type         = "auth"
      filter           = "All Logs"
      send_to_panorama = true
      http             = ["Azure"]
    },
    {
      name             = "Data Logs"
      log_type         = "data"
      filter           = "All Logs"
      send_to_panorama = true
      http             = ["Azure"]
    },
    {
      name             = "Decryption Logs"
      log_type         = "decryption"
      filter           = "All Logs"
      send_to_panorama = true
      http             = ["Azure"]
    },
    {
      name             = "Tunnel Logs"
      log_type         = "tunnel"
      filter           = "All Logs"
      send_to_panorama = true
      http             = ["Azure"]
    },
    {
      name             = "URL Logs"
      log_type         = "url"
      filter           = "All Logs"
      send_to_panorama = true
      http             = ["Azure"]
    }
  ]
}


resource "panos_application_group" "denied_apps" {
  location = {
    device_group = {
      name = panos_device_group.main.name
    }
  }
  name = "DENIED-APPS"

  members = [
    # "application-filter.risk_5_apps"
  ]
}