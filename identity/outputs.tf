output "vnet_id" {
  value = azurerm_virtual_network.identity.id
}

output "des_id" {
  value = module.key_vault.des_id
}

output "combined_dcr_id" {
  value = azurerm_monitor_data_collection_rule.windows_dcr.id
}

output "local_law_id" {
  value = azurerm_log_analytics_workspace.local_law.id
}

output "nsg_ids" {
  description = "Map of NSG names to IDs for flow log archival"
  value = {
    "nsg-ad" = azurerm_network_security_group.nsg_ad.id
  }
}

output "vm_ids" {
  description = "List of Windows VM IDs for DCR association"
  value = [
    module.actdirazp01.id,
    module.actdirazp02.id
  ]
}