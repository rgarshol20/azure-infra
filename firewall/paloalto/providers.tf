provider "azurerm" {
  subscription_id = var.main_subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  features {}
}

provider "azurerm" {
  alias           = "logging"
  subscription_id = var.logging_subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  features {}
}

provider "azurerm" {
  alias           = "firewall"
  subscription_id = var.firewall_subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  features {}
}

provider "azurerm" {
  alias           = "billings"
  subscription_id = var.dev_subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  features {}
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.29.0"
    }
    panos = {
      source  = "paloaltonetworks/panos"
      version = "2.0.2"
    }
  }
}
