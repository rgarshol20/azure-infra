output "id" {
  description = "Virtual machine resource ID"
  value       = azurerm_windows_virtual_machine.this.id
}

output "name" {
  description = "Virtual machine name"
  value       = azurerm_windows_virtual_machine.this.name
}

output "private_ip_address" {
  description = "Private IP address"
  value       = azurerm_network_interface.this.private_ip_address
}

output "network_interface_id" {
  description = "Network interface resource ID"
  value       = azurerm_network_interface.this.id
}

output "identity_principal_id" {
  description = "System-assigned managed identity principal ID"
  value       = azurerm_windows_virtual_machine.this.identity[0].principal_id
}

output "data_disk_ids" {
  description = "Data disk resource IDs"
  value       = [for disk in azurerm_managed_disk.data : disk.id]
}

output "vm" {
  description = "Complete VM object"
  value       = azurerm_windows_virtual_machine.this
}
