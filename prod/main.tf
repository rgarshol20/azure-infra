resource "azurerm_resource_group" "logging" {
  provider = azurerm.prod
  name     = "rg-prod-logs"
  location = var.location

  tags = local.required_tags
}

resource "azurerm_resource_group" "networking" {
  provider = azurerm.prod
  name     = "rg-prod-networking"
  location = var.location

  tags = local.required_tags
}

resource "azurerm_resource_group" "servers" {
  provider = azurerm.prod
  name     = "rg-prod-servers"
  location = var.location

  tags = local.required_tags
}
resource "azurerm_resource_group" "workers" {
  provider = azurerm.prod
  name     = "rg-prod-workers"
  location = var.location

  tags = local.required_tags
}

resource "azurerm_resource_group" "backup" {
  provider = azurerm.prod
  name     = "rg-prod-backup"
  location = var.location

  tags = local.required_tags
}





data "azurerm_image" "win2022_base_image" {
  provider            = azurerm.prod
  name                = "2022_base_image" # your custom image name
  resource_group_name = "rg-prod-images"
}
data "azurerm_image" "win2022_wrk_image" {
  provider            = azurerm.prod
  name                = "2022_wrk_image" # your custom image name
  resource_group_name = "rg-prod-images"
}
data "azurerm_image" "win2022_ads_image" {
  provider            = azurerm.prod
  name                = "2022_ads_image" # your custom image name
  resource_group_name = "rg-prod-images"
}

data "azurerm_image" "imageBIZFTPAZP01" {
  provider            = azurerm.prod
  name                = "imageBIZFTPAZP01" # your custom image name
  resource_group_name = "rg-prod-images"
}

data "azurerm_image" "imageBIZWRKZAP" {
  provider            = azurerm.prod
  name                = "BIZWRKZAP" # your custom image name
  resource_group_name = "rg-prod-images"
}
