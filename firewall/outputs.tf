# output "firewall_private_ip" {
#   value = azurerm_network_interface.firewall_nic_private.private_ip_address
# }

output "firewall_public_ip" {
  value = azurerm_public_ip.acme-health-svcs_pip.ip_address
}

output "firewall_mgmt_ip" {
  value = azurerm_public_ip.mgmtsvcs_pip.ip_address
}

output "panorama_public_ip" {
  value = azurerm_public_ip.panorama_public_ip.ip_address
}

output "vnet_id" {
  value = azurerm_virtual_network.firewall.id
}

output "nsg_mgmt_id" {
  value = azurerm_network_security_group.mgmt_nsg.id
}

output "nsg_public_id" {
  value = azurerm_network_security_group.public_nsg.id
}

output "nsg_twingate_id" {
  value = azurerm_network_security_group.twingate_nsg.id
}

output "des_id" {
  value = module.key_vault.des_id
}

output "combined_dcr_id" {
  value = azurerm_monitor_data_collection_rule.windows_dcr.id
}

output "nsg_ids" {
  description = "Map of NSG names to IDs for flow log archival"
  value = {
    "mgmt-nsg"     = azurerm_network_security_group.mgmt_nsg.id
    "public-nsg"   = azurerm_network_security_group.public_nsg.id
    "private-nsg"  = azurerm_network_security_group.private_nsg.id
    "twingate-nsg" = azurerm_network_security_group.twingate_nsg.id
    "ad-nsg"       = azurerm_network_security_group.ad_nsg.id
  }
}

output "vm_ids" {
  description = "List of Windows VM IDs for DCR association (firewall has no Windows VMs, only Linux/Palo Alto)"
  value       = []
}
