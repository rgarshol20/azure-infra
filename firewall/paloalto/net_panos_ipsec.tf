# Example full VPN stack in PAN-OS v2 Terraform
# 1. IKE Crypto Profile (Phase 1)
resource "panos_ike_crypto_profile" "ike_profile" {
  name = "ike-profile-ahds"
  location = {
    template = {
      name = panos_template.main.name
      vsys = "vsys1"
    }
  }

  dh_group   = ["group5"]
  encryption = ["aes-256-cbc"]
  hash       = ["sha1"]
  lifetime = {
    seconds = 28800
  }
}

# 2. IPSec Crypto Profile (Phase 2)
resource "panos_ipsec_crypto_profile" "ipsec_profile" {
  name = "ipsec-profile-ahds"

  location = {
    template = {
      name = panos_template.main.name
      vsys = "vsys1"
    }
  }

  dh_group = "group5"
  esp = {
    encryption     = ["aes-256-cbc"]
    authentication = ["sha1"]
  }

  lifetime = {
    seconds = 28800
  }
}

# 4. IKE Gateway
resource "panos_ike_gateway" "ike_gateway" {
  name = "ike-gw-ahds"

  location = {
    template = {
      name = panos_template.main.name
      vsys = "vsys1"
    }
  }

  local_address = {
    interface = "ethernet1/1"
    # ip = "10.99.1.4/30"
  }

  local_id = {
    type = "ipaddr"
    id   = "4.155.104.150"
  }

  peer_id = {
    type = "ipaddr"
    id   = "72.5.187.88"
  }

  protocol_common = {
    nat_traversal = {
      enable = false
      # keep_alive_interval = 20
    }
    fragmentation = {
      enable = false
    }
  }

  peer_address = {
    ip = "72.5.187.88"
  }

  # authentication = {
  #   type            = "pre-shared-key"
  #   pre_shared_key = {
  #     value = var.ahds_password
  #   }
  # }

  protocol = {
    version = "ikev2-preferred"
    ikev1 = {
      ike_crypto_profile = panos_ike_crypto_profile.ike_profile.name

      dpd = {
        enable = false
      }
    }
    ikev2 = {
      ike_crypto_profile = panos_ike_crypto_profile.ike_profile.name

      dpd = {
        enable = false
      }
    }
  }

  lifecycle {
    ignore_changes = [
      authentication[0].pre_shared_key[0].key
    ]
  }

}

# 5. IPSec Tunnel
resource "panos_ipsec_tunnel" "ipsec_tunnel" {
  name = "ipsec-tunnel-ahds"

  location = {
    template = {
      name = panos_template.main.name
      vsys = "vsys1"
    }
  }

  tunnel_interface = panos_tunnel_interface.tunnel1.name
  auto_key = {
    ike_gateway = [{
      name = panos_ike_gateway.ike_gateway.name
    }]

    ipsec_crypto_profile = panos_ipsec_crypto_profile.ipsec_profile.name
    proxy_id = [{
      name   = "ahds"
      local  = "100.64.203.54/32"
      remote = "100.64.47.0/24"
      protocol = {
        any = {}
      }
    }]

  }
}

