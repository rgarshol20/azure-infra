output "container_group_name" {
  description = "Name of the ACI container group"
  value       = azurerm_container_group.backup.name
}

output "container_group_id" {
  description = "Resource ID of the ACI container group"
  value       = azurerm_container_group.backup.id
}

output "container_principal_id" {
  description = "Managed identity principal ID for the container group"
  value       = azurerm_container_group.backup.identity[0].principal_id
}

output "storage_account_name" {
  description = "Storage account name for config archives"
  value       = azurerm_storage_account.backup.name
}

output "storage_account_id" {
  description = "Resource ID of the backup storage account"
  value       = azurerm_storage_account.backup.id
}

output "key_vault_id" {
  description = "Resource ID of the Key Vault"
  value       = azurerm_key_vault.backup.id
}

output "key_vault_uri" {
  description = "Key Vault URI for secret references"
  value       = azurerm_key_vault.backup.vault_uri
}
