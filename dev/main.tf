resource "azurerm_resource_group" "networking" {
  provider = azurerm.dev
  name     = "rg-dev-networking"
  location = var.location

  tags = local.required_tags
}

resource "azurerm_resource_group" "logging" {
  provider = azurerm.dev
  name     = "rg-dev-logs"
  location = var.location

  tags = local.required_tags
}

resource "azurerm_resource_group" "servers" {
  provider = azurerm.dev
  name     = "rg-dev-servers"
  location = var.location

  tags = local.required_tags
}

resource "azurerm_resource_group" "workers" {
  provider = azurerm.dev
  name     = "rg-dev-workers"
  location = var.location

  tags = local.required_tags
}

resource "azurerm_resource_group" "backup" {
  provider = azurerm.dev
  name     = "rg-dev-backup"
  location = var.location

  tags = local.required_tags
}
data "azurerm_image" "imageCGIRDPAZT01" {
  provider            = azurerm.dev
  name                = "imageCGIRDPAZT01" # your custom image name
  resource_group_name = "rg-dev-images"
}

data "azurerm_image" "win2022_base_image" {
  provider            = azurerm.dev
  name                = "win2022-base-image" # your custom image name
  resource_group_name = "rg-dev-images"
}

data "azurerm_image" "win2022_mysql_image" {
  provider            = azurerm.dev
  name                = "win2022-mysql-image" # your custom image name
  resource_group_name = "rg-dev-images"
}

# data "azurerm_image" "win2022_wkr_image" {
#   provider            = azurerm.dev  
#   name                = "win2022-wkr-image"             # your custom image name
#   resource_group_name = "rg-dev-images"
# }


# data "azurerm_image" "win2022_fpt_image" {
#   provider            = azurerm.dev  
#   name                = "win2022-ftp-image"             # your custom image name
#   resource_group_name = "rg-dev-images"
# }