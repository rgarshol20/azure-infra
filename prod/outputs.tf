
output "subnet_workers_id" {
  value = azurerm_subnet.workers.id
}

output "vnet_id" {
  value = azurerm_virtual_network.prod.id
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
    "nsg-servers" = azurerm_network_security_group.nsg_servers.id
    "nsg-workers" = azurerm_network_security_group.nsg_workers.id
  }
}

output "vm_ids" {
  description = "List of Windows VM IDs for DCR association"
  value = concat(
    [module.veeamazp01.id],
    [for k, v in module.bizwrkazp : v.id],
    [module.bizarcazp01.id],
    [module.nntfimazp01.id],
    [module.cgirdpazp01.id],
    [module.cgiadsazp01.id],
    [module.bizftpazp01.id],
    [module.bizadsazp01.id]
  )
}