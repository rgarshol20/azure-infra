resource "azurerm_resource_group" "logging" {
  provider = azurerm.logging
  name     = "rg-logging-logs"
  location = var.location

  tags = local.required_tags
}