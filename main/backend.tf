terraform {
  backend "azurerm" {
    resource_group_name  = "rg-main-terraform"
    storage_account_name = "acme-health-terraform-state"
    container_name       = "terraform-state"
    key                  = "main.terraform.tfstate"

    # Use Azure AD authentication
    use_azuread_auth = true
    # use_oidc         = true  # Set via ARM_USE_OIDC env var in CI
  }
}