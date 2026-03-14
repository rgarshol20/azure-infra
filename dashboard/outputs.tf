
output "hipaa_logs_workspace_id" {
  value = azurerm_log_analytics_workspace.local_law.id
}

output "hipaa_key_vault_id" {
  value = module.key_vault.id
}

output "hipaa_key_id" {
  value = module.key_vault.cmk_id
}

output "combined_dcr_id" {
  value = azurerm_monitor_data_collection_rule.windows_dcr.id
}

# output "function_app_url" {
#   value = "https://${azurerm_linux_function_app.palo_function.default_hostname}"
# }

output "hipaa_des_id" {
  value = module.key_vault.des_id
}

output "vnet_id" {
  value = azurerm_virtual_network.dashboard.id
}

output "nsg_ids" {
  description = "Map of NSG names to IDs for flow log archival"
  value = {
    "nsg-servers" = azurerm_network_security_group.nsg_servers.id
    "nsg-workers" = azurerm_network_security_group.nsg_workers.id
  }
}

output "vm_ids" {
  description = "List of Windows VM IDs for DCR association"
  value = [
    module.bizinetazt01.id,
  ]
}
