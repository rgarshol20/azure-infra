resource "panos_security_policy" "main" {
  location = {
    device_group = {
      name = panos_device_group.main.name
    }
  }

  rules = [

    {
      name                  = "DENIED-APPS"
      rule_type             = "universal"
      source_zones          = ["any"]
      source_addresses      = ["any"]
      source_users          = ["any"]
      destination_zones     = ["Untrust"]
      destination_addresses = ["any"]
      applications          = ["DENIED-APPS"]
      services              = ["application-default"]
      categories            = ["any"]
      action                = "deny"
      log_setting           = "Azure"
      log_end               = true
    },
    {
      name                  = "Untrust Outbound"
      rule_type             = "universal"
      source_zones          = ["Untrust"]
      source_addresses      = ["10.99.1.4"]
      source_users          = ["any"]
      destination_zones     = ["Untrust"]
      destination_addresses = ["any"]
      applications          = ["any"]
      services              = ["any"]
      categories            = ["any"]
      action                = "allow"
      log_setting           = "Azure"
      log_end               = true
    },
    {
      name                  = "VPN Tunnels"
      rule_type             = "universal"
      source_zones          = ["Untrust"]
      source_addresses      = ["10.99.1.4"]
      source_users          = ["any"]
      destination_zones     = ["VPN"]
      destination_addresses = ["any"]
      applications          = ["any"]
      services              = ["any"]
      categories            = ["any"]
      action                = "allow"
      log_setting           = "Azure"
      log_end               = true
    },
    {
      name                  = "AHDS"
      rule_type             = "universal"
      source_zones          = ["Trust"]
      source_addresses      = ["any"]
      source_users          = ["any"]
      destination_zones     = ["VPN"]
      destination_addresses = ["any"]
      applications          = ["any"]
      services              = ["any"]
      categories            = ["any"]
      action                = "allow"
      log_setting           = "Azure"
      log_end               = true
    },
    {
      name                  = "Twingate"
      rule_type             = "universal"
      source_zones          = ["Trust"]
      source_addresses      = ["10.99.5.0/24"]
      source_users          = ["any"]
      destination_zones     = ["Untrust"]
      destination_addresses = ["any"]
      applications          = ["any"]
      services              = ["service-https", "Twingate_TCP_Ports", "Twingate_UDP_Ports"]
      categories            = ["any"]
      action                = "allow"
      log_setting           = "Azure"
      log_end               = true
    },



    {
      name                  = "Umbrella DNS"
      rule_type             = "universal"
      source_zones          = ["Trust"]
      source_addresses      = ["any"]
      source_users          = ["any"]
      destination_zones     = ["Untrust"]
      destination_addresses = ["208.67.220.220", "208.67.222.222"]
      applications          = ["dns"]
      services              = ["application-default"]
      categories            = ["any"]
      action                = "allow"
      log_setting           = "Azure"
      log_end               = true
      profile_setting = {
        group = ["AcmeHealth-Full-Protection"]
      }
    },

    {
      name                  = "PAN Update"
      rule_type             = "universal"
      source_zones          = ["Trust"]
      source_addresses      = ["any"]
      destination_zones     = ["Untrust"]
      destination_addresses = ["Updates"]
      applications          = ["any"]
      services              = ["any"]
      action                = "allow"
      log_setting           = "Azure"
      log_end               = true
      profile_setting = {
        group = ["AcmeHealth-Full-Protection"]
      }
    },

    {
      name                  = "NTP"
      rule_type             = "universal"
      source_zones          = ["Trust"]
      source_addresses      = ["any"]
      destination_zones     = ["Untrust"]
      destination_addresses = ["NTP_SERVERS"]
      applications          = ["any"]
      services              = ["NTP_TCP", "NTP_UDP"]
      action                = "allow"
      log_setting           = "Azure"
      log_end               = true
      profile_setting = {
        group = ["AcmeHealth-Full-Protection"]
      }
    },



    {
      name                  = "XDR"
      rule_type             = "universal"
      source_zones          = ["Trust"]
      source_addresses      = ["any"]
      destination_zones     = ["Untrust"]
      destination_addresses = ["any"]
      applications          = ["cortex-xdr", "cortex-xdr-agent-scan", "google-base", "paloalto-traps", "ssl", "traps-management-service"]
      services              = ["application-default"]
      category              = ["PAN-CORTEX"]
      action                = "allow"
      log_setting           = "Azure"
      log_end               = true
      profile_setting = {
        group = ["AcmeHealth-Full-Protection"]
      }
    },

    {
      name                  = "MS-UPDATES-443"
      rule_type             = "universal"
      source_zones          = ["Trust"]
      source_addresses      = ["any"]
      destination_zones     = ["Untrust"]
      destination_addresses = ["any"]
      applications          = ["ms-update", "ocsp", "ssl", "web-browsing"]
      services              = ["application-default"]
      action                = "allow"
      log_setting           = "Azure"
      log_end               = true
    },

    {
      name                  = "MS-UPDATES-80"
      rule_type             = "universal"
      source_zones          = ["Trust"]
      source_addresses      = ["any"]
      destination_zones     = ["Untrust"]
      destination_addresses = ["any"]
      applications          = ["ms-update"]
      services              = ["any"]
      action                = "allow"
      log_setting           = "Azure"
      log_end               = true
    },

    {
      name                  = "INTERNET-TRUST"
      rule_type             = "universal"
      source_zones          = ["Trust"]
      source_addresses      = ["any"]
      destination_zones     = ["Untrust"]
      destination_addresses = ["any"]
      applications          = ["any"]
      services              = ["any"]
      action                = "allow"
      log_setting           = "Azure"
      log_end               = true
      # profile_setting = {
      #   group = ["AcmeHealth-Full-Protection"]
      #   }
    },
    {
      name                  = "Containment"
      rule_type             = "universal"
      source_zones          = ["any"]
      source_addresses      = ["any"]
      destination_zones     = ["any"]
      destination_addresses = ["any"]
      applications          = ["any"]
      services              = ["any"]
      action                = "deny"
      log_setting           = "Azure"
      log_end               = true
    }
  ]
}

resource "panos_nat_policy" "main" {
  location = {
    device_group = {
      name     = panos_device_group.main.name
      rulebase = "post-rulebase"
    }
  }

  rules = [

    {
      name = "VPN-AHDS"

      source_zones          = ["Trust"]
      source_addresses      = ["any"]
      destination_zone      = ["VPN"]
      destination_addresses = ["any"]
      destination_interface = "tunnel.1"
      services              = ["any"]

      source_translation = {
        dynamic_ip_and_port = {
          interface_address = {
            interface = "tunnel.1"
            ip        = "100.64.203.54"
          }
        }
      }
    },
    {
      name = "Outbound-NAT"

      source_zones          = ["any"]
      source_addresses      = ["any"]
      destination_zone      = ["Untrust"]
      destination_addresses = ["any"]
      services              = ["any"]

      source_translation = {
        dynamic_ip_and_port = {
          interface_address = {
            interface = "ethernet1/1"
            ip        = "10.99.1.4"
          }
        }
      }
    }

  ]
}