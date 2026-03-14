output "vault_id" {
  description = "The Recovery Services Vault resource ID"
  value       = azurerm_recovery_services_vault.this.id
}

output "vault_name" {
  description = "The Recovery Services Vault name"
  value       = azurerm_recovery_services_vault.this.name
}

output "backup_policy_ids" {
  description = "Map of backup policy names to IDs (all types)"
  value = merge(
    { for k, v in azurerm_backup_policy_vm.vm_policies : k => v.id },
    { for k, v in azurerm_backup_policy_vm_workload.sql_policies : k => v.id },
    { for k, v in azurerm_backup_policy_file_share.file_share_policies : k => v.id }
  )
}
