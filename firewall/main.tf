resource "azurerm_resource_group" "firewall" {
  provider = azurerm.firewall
  name     = "rg-firewall-networking"
  location = var.location

  tags = local.required_tags
}

resource "azurerm_resource_group" "logging" {
  provider = azurerm.firewall
  name     = "rg-firewall-logs"
  location = var.location

  tags = local.required_tags
}

data "azuread_service_principal" "github_deploy_sp" {
  display_name = "github-deploy-app"
}

data "azuread_service_principal" "audit_sp" {
  display_name = "kobe-security-audit"
}






