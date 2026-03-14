# in outputs.tf of main account
output "central_storage_account_id" {
  value = azurerm_storage_account.encrypted_storage.id
}
output "github_deploy_sp_object_id" {
  value = azuread_service_principal.github_deploy_sp.object_id
}
