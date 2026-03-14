# Remote state data sources for azure-infra modules
# Eliminates duplication of terraform_remote_state blocks

data "terraform_remote_state" "logging" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.state_resource_group
    storage_account_name = var.state_storage_account
    container_name       = var.state_container
    key                  = "logging.terraform.tfstate"
    use_azuread_auth     = var.use_azuread_auth
    use_oidc             = var.use_oidc
  }
}

data "terraform_remote_state" "main" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.state_resource_group
    storage_account_name = var.state_storage_account
    container_name       = var.state_container
    key                  = "main.terraform.tfstate"
    use_azuread_auth     = var.use_azuread_auth
    use_oidc             = var.use_oidc
  }
}

data "terraform_remote_state" "identity" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.state_resource_group
    storage_account_name = var.state_storage_account
    container_name       = var.state_container
    key                  = "identity.terraform.tfstate"
    use_azuread_auth     = var.use_azuread_auth
    use_oidc             = var.use_oidc
  }
}

data "terraform_remote_state" "firewall" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.state_resource_group
    storage_account_name = var.state_storage_account
    container_name       = var.state_container
    key                  = "firewall.terraform.tfstate"
    use_azuread_auth     = var.use_azuread_auth
    use_oidc             = var.use_oidc
  }
}

data "terraform_remote_state" "prod" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.state_resource_group
    storage_account_name = var.state_storage_account
    container_name       = var.state_container
    key                  = "prod.terraform.tfstate"
    use_azuread_auth     = var.use_azuread_auth
    use_oidc             = var.use_oidc
  }
}

data "terraform_remote_state" "dev" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.state_resource_group
    storage_account_name = var.state_storage_account
    container_name       = var.state_container
    key                  = "dev.terraform.tfstate"
    use_azuread_auth     = var.use_azuread_auth
    use_oidc             = var.use_oidc
  }
}

data "terraform_remote_state" "dashboard" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.state_resource_group
    storage_account_name = var.state_storage_account
    container_name       = var.state_container
    key                  = "dashboard.terraform.tfstate"
    use_azuread_auth     = var.use_azuread_auth
    use_oidc             = var.use_oidc
  }
}
