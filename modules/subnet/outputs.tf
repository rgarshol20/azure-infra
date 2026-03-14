output "id" {
  description = "Subnet resource ID"
  value       = azurerm_subnet.this.id
}

output "name" {
  description = "Subnet name"
  value       = azurerm_subnet.this.name
}

output "address_prefixes" {
  description = "Subnet address prefixes"
  value       = azurerm_subnet.this.address_prefixes
}

output "subnet" {
  description = "Complete subnet object"
  value       = azurerm_subnet.this
}
