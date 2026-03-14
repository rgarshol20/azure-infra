output "id" {
  description = "Key vault resource ID"
  value       = azurerm_key_vault.this.id
}

output "name" {
  description = "Key vault name"
  value       = azurerm_key_vault.this.name
}

output "vault_uri" {
  description = "Key vault URI"
  value       = azurerm_key_vault.this.vault_uri
}

output "key_vault" {
  description = "Complete key vault object"
  value       = azurerm_key_vault.this
}

output "cmk_id" {
  description = "Customer-managed key ID (if created)"
  value       = var.create_cmk ? azurerm_key_vault_key.cmk[0].id : null
}

output "cmk_version" {
  description = "Customer-managed key version (if created)"
  value       = var.create_cmk ? azurerm_key_vault_key.cmk[0].version : null
}

output "des_id" {
  description = "Disk Encryption Set ID (if created)"
  value       = var.create_cmk && var.create_des ? azurerm_disk_encryption_set.this[0].id : null
}

output "des_principal_id" {
  description = "Disk Encryption Set managed identity principal ID (if created)"
  value       = var.create_cmk && var.create_des ? azurerm_disk_encryption_set.this[0].identity[0].principal_id : null
}

output "admin_password_secret_id" {
  description = "Admin password secret ID (if created)"
  value       = var.create_admin_password ? azurerm_key_vault_secret.admin_password[0].id : null
  sensitive   = true
}

output "admin_password_value" {
  description = "Admin password secret value (if created)"
  value       = var.create_admin_password ? azurerm_key_vault_secret.admin_password[0].value : null
  sensitive   = true
}
