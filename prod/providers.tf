provider "azurerm" {
  subscription_id = var.main_subscription_id
  features {}
  storage_use_azuread = true
  use_oidc            = true # Add this
}

provider "azurerm" {
  alias           = "logging"
  subscription_id = var.logging_subscription_id
  features {}
  storage_use_azuread = true
  use_oidc            = true # Add this
}

provider "azurerm" {
  alias           = "firewall"
  subscription_id = var.firewall_subscription_id
  features {}
  storage_use_azuread = true
  use_oidc            = true # Add this
}

provider "azurerm" {
  alias           = "prod"
  subscription_id = var.prod_subscription_id
  features {}
  storage_use_azuread = true
  use_oidc            = true # Add this
}

provider "azurerm" {
  alias           = "identity"
  subscription_id = var.identity_subscription_id
  features {}
  storage_use_azuread = true
  use_oidc            = true # Add this
}

provider "azurerm" {
  alias           = "dev"
  subscription_id = var.dev_subscription_id
  features {}
  storage_use_azuread = true
  use_oidc            = true # Add this
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.34"
    }
    azuread = {                     # ADD THIS
      source  = "hashicorp/azuread" # ADD THIS
      version = "~> 3.0"            # ADD THIS - use latest 3.x
    }
    panos = {
      source  = "paloaltonetworks/panos"
      version = ">= 2.0.0"
    }
  }
}

