output "storage_account_id" {
  description = "Resource ID of the HIPAA log archive storage account"
  value       = azurerm_storage_account.archive.id
}

output "storage_account_name" {
  description = "Name of the HIPAA log archive storage account"
  value       = azurerm_storage_account.archive.name
}

output "dcr_id" {
  description = "Resource ID of the Windows VM Data Collection Rule (if created)"
  value       = length(azurerm_monitor_data_collection_rule.windows_archive) > 0 ? azurerm_monitor_data_collection_rule.windows_archive[0].id : null
}

output "containers" {
  description = "Map of container names to their resource IDs"
  value = {
    entra_logs    = azurerm_storage_container.entra_logs.name
    activity_logs = azurerm_storage_container.activity_logs.name
    nsg_flow_logs = azurerm_storage_container.nsg_flow_logs.name
    vm_logs       = azurerm_storage_container.vm_logs.name
  }
}
