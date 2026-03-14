resource "azurerm_resource_group" "dashboard" {
  provider = azurerm.dashboard
  name     = "Networking"
  location = "centralus"

  tags = local.required_tags
}

resource "azurerm_container_group" "twingate_connector_copper_tarsier" {
  #checkov:skip=CKV_AZURE_235:Twingate connector requires plain env vars; secure_environment_variables not supported by connector image
  provider            = azurerm.dashboard
  name                = "twingate-connector-copper-tarsier"
  location            = "centralus"
  resource_group_name = "Networking"
  os_type             = "Linux"
  ip_address_type     = "Private"
  subnet_ids          = ["/subscriptions/${var.dashboard_subscription_id}/resourceGroups/Networking/providers/Microsoft.Network/virtualNetworks/CustomerVNET/subnets/Twingate"]
  restart_policy      = "Always"

  container {
    name   = "twingate"
    image  = "twingate/connector:latest"
    cpu    = "0.5"
    memory = "1.5"

    environment_variables = {
      TWINGATE_NETWORK       = var.twingate_network
      TWINGATE_ACCESS_TOKEN  = var.twingate_copper_tarsier_access_token
      TWINGATE_REFRESH_TOKEN = var.twingate_copper_tarsier_refresh_token
      TWINGATE_URL_SLUG      = var.twingate_url_slug
    }

    ports {
      port = 443
    }
  }

  image_registry_credential {
    server   = "index.docker.io"
    username = var.docker_username
    password = var.docker_password
  }

  tags = {
    environment = "dde"
    role        = "twingate"
  }
}

resource "azurerm_container_group" "twingate_connector_super_woodlouse" {
  #checkov:skip=CKV_AZURE_235:Twingate connector requires plain env vars; secure_environment_variables not supported by connector image
  provider            = azurerm.dashboard
  name                = "twingate-connector-super-woodlouse"
  location            = "centralus"
  resource_group_name = "Networking"
  os_type             = "Linux"
  ip_address_type     = "Private"
  subnet_ids          = ["/subscriptions/${var.dashboard_subscription_id}/resourceGroups/Networking/providers/Microsoft.Network/virtualNetworks/CustomerVNET/subnets/Twingate"]
  restart_policy      = "Always"

  container {
    name   = "twingate"
    image  = "twingate/connector:latest"
    cpu    = "0.5"
    memory = "1.5"

    environment_variables = {
      TWINGATE_NETWORK       = var.twingate_network
      TWINGATE_ACCESS_TOKEN  = var.twingate_super_woodlouse_access_token
      TWINGATE_REFRESH_TOKEN = var.twingate_super_woodlouse_refresh_token
      TWINGATE_URL_SLUG      = var.twingate_url_slug
    }

    ports {
      port = 443
    }
  }

  image_registry_credential {
    server   = "index.docker.io"
    username = var.docker_username
    password = var.docker_password
  }

  tags = {
    environment = "dashboard"
    role        = "twingate"
  }
}
