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
      version = "4.34.0"
    }
    azuread = {                     # ADD THIS
      source  = "hashicorp/azuread" # ADD THIS
      version = "~> 3.0"            # ADD THIS - use latest 3.x
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    panos = {
      source  = "paloaltonetworks/panos"
      version = ">= 2.0.0"
    }
    microsoft365 = {
      source  = "deploymenttheory/microsoft365"
      version = "0.48.0-alpha"
    }
  }
}

# Microsoft 365 provider — uses the same OIDC service principal as azuread/azurerm.
# Auth is driven entirely by environment variables; set these in the workflow alongside ARM_*:
#   M365_TENANT_ID    = same as ARM_TENANT_ID
#   M365_CLIENT_ID    = same as ARM_CLIENT_ID
#   M365_AUTH_METHOD  = github_oidc
# The deploy SP needs: DeviceManagementConfiguration.ReadWrite.All, Directory.Read.All
provider "microsoft365" {
  tenant_id   = var.tenant_id
  auth_method = var.m365_auth_method
  cloud       = "public"
}

