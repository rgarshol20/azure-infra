# Resource Group for Terraform infra
resource "azurerm_resource_group" "terraform" {
  name     = "rg-main-terraform"
  location = var.location

  tags = local.required_tags
}

# Resource Group for Terraform infra
resource "azurerm_resource_group" "logging" {
  name     = "rg-main-logs"
  location = var.location

  tags = local.required_tags
}

