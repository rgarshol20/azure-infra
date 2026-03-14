resource "azurerm_resource_group" "networking" {
  provider = azurerm.dashboard
  name     = "rg-dashboard-networking"
  location = var.location

  tags = local.required_tags
}

data "azuread_service_principal" "github_deploy_sp" {
  display_name = "github-deploy-app"
}

resource "azurerm_resource_group" "logging" {
  provider = azurerm.dashboard
  name     = "rg-dashboard-logs"
  location = var.location

  tags = local.required_tags
}

resource "azurerm_resource_group" "servers" {
  provider = azurerm.dashboard
  name     = "rg-dashboard-servers"
  location = var.location

  tags = local.required_tags
}

resource "azurerm_resource_group" "workers" {
  provider = azurerm.dashboard
  name     = "rg-dashboard-workers"
  location = var.location

  tags = local.required_tags
}

resource "azurerm_resource_group" "backup" {
  provider = azurerm.dashboard
  name     = "rg-dashboard-backup"
  location = var.location

  tags = local.required_tags
}



