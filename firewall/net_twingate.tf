resource "azurerm_container_group" "twingate_connector_prophetic_magpie" {
  #checkov:skip=CKV_AZURE_235:Twingate connector requires plain env vars; secure_environment_variables not supported by connector image
  provider            = azurerm.firewall
  name                = "twingate-connector-prophetic-magpie"
  location            = azurerm_resource_group.firewall.location
  resource_group_name = azurerm_resource_group.firewall.name
  os_type             = "Linux"
  ip_address_type     = "Private"
  subnet_ids          = [azurerm_subnet.twingate.id]
  restart_policy      = "Always"

  container {
    name   = "twingate"
    image  = "twingate/connector:latest"
    cpu    = "0.5"
    memory = "1.5"

    environment_variables = {
      TWINGATE_NETWORK       = var.twingate_network
      TWINGATE_ACCESS_TOKEN  = var.twingate_prophetic_magpie_access_token
      TWINGATE_REFRESH_TOKEN = var.twingate_prophetic_magpie_refresh_token
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

  tags = local.required_tags
}

resource "azurerm_container_group" "twingate_connector_outstanding_hampster" {
  #checkov:skip=CKV_AZURE_235:Twingate connector requires plain env vars; secure_environment_variables not supported by connector image
  provider            = azurerm.firewall
  name                = "twingate-connector-outstanding-hampster"
  location            = azurerm_resource_group.firewall.location
  resource_group_name = azurerm_resource_group.firewall.name
  os_type             = "Linux"
  ip_address_type     = "Private"
  subnet_ids          = [azurerm_subnet.twingate.id]
  restart_policy      = "Always"

  container {
    name   = "twingate"
    image  = "twingate/connector:latest"
    cpu    = "0.5"
    memory = "1.5"

    environment_variables = {
      TWINGATE_NETWORK       = var.twingate_network
      TWINGATE_ACCESS_TOKEN  = var.twingate_outstanding_hampster_access_token
      TWINGATE_REFRESH_TOKEN = var.twingate_outstanding_hampster_refresh_token
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

  tags = local.required_tags
}
