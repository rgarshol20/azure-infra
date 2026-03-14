output "resource_group" {
  description = "The complete resource group object"
  value       = azurerm_resource_group.this
}

output "name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.this.name
}

output "location" {
  description = "The location of the resource group"
  value       = azurerm_resource_group.this.location
}

output "id" {
  description = "The resource ID of the resource group"
  value       = azurerm_resource_group.this.id
}
