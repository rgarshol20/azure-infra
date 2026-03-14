# # Access to the Terraform backend storage account (adjust scope/resource)
# resource "azurerm_role_assignment" "user_admin_access" {
#   provider = azurerm.firewall  
#   scope                = "/subscriptions/${var.firewall_subscription_id}"
#   role_definition_name = "User Access Administrator"
#   principal_id = data.azuread_service_principal.github_deploy_sp.object_id
# }

# # Access to the Terraform backend storage account (adjust scope/resource)
# resource "azurerm_role_assignment" "key_vault_reader_access" {
#   provider             = azurerm.firewall
#   scope                = module.key_vault.id
#   role_definition_name = "Reader"
#   principal_id         = data.azuread_service_principal.github_deploy_sp.object_id
# }

# # Access to the Terraform backend storage account (adjust scope/resource)
# resource "azurerm_role_assignment" "key_vault_crypto_access" {
#   provider             = azurerm.firewall
#   scope                = module.key_vault.id
#   role_definition_name = "Key Vault Administrator" # ✅ Required for Disk Encryption Set
#   principal_id         = data.azuread_service_principal.github_deploy_sp.object_id
# }