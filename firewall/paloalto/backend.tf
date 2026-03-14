terraform {
  backend "azurerm" {
    resource_group_name  = "rg-main-terraform"
    storage_account_name = "acme-health-ddestorage"
    container_name       = "terraform-state"
    key                  = "firewall-panos.terraform.tfstate"

    # Use Azure AD authentication
    use_azuread_auth = true
    use_oidc         = true
  }
}