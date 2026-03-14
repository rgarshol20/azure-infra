output "id" {
  description = "Virtual network resource ID"
  value       = azurerm_virtual_network.this.id
}

output "name" {
  description = "Virtual network name"
  value       = azurerm_virtual_network.this.name
}

output "address_space" {
  description = "Virtual network address space"
  value       = azurerm_virtual_network.this.address_space
}

output "virtual_network" {
  description = "Complete virtual network object"
  value       = azurerm_virtual_network.this
}
