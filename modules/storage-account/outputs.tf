output "id" {
  description = "Storage account resource ID"
  value       = azurerm_storage_account.this.id
}

output "name" {
  description = "Storage account name"
  value       = azurerm_storage_account.this.name
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "primary_blob_host" {
  description = "Primary blob host"
  value       = azurerm_storage_account.this.primary_blob_host
}

output "storage_account" {
  description = "Complete storage account object"
  value       = azurerm_storage_account.this
}
