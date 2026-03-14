resource "azurerm_resource_group" "logging" {
  provider = azurerm.identity
  name     = "rg-identity-logs"
  location = var.location

  tags = local.required_tags
}

resource "azurerm_resource_group" "networking" {
  provider = azurerm.identity
  name     = "rg-identity-networking"
  location = var.location

  tags = local.required_tags
}

resource "azurerm_resource_group" "ad" {
  provider = azurerm.identity
  name     = "rg-identity-ad"
  location = var.location

  tags = local.required_tags
}

resource "azurerm_resource_group" "backup" {
  provider = azurerm.identity
  name     = "rg-identity-backup"
  location = var.location

  tags = local.required_tags
}






