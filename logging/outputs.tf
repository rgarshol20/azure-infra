output "central_eventhub_namespace_name" {
  description = "The name of the central Event Hub namespace"
  value       = azurerm_eventhub_namespace.central_ns.name
}

output "central_eventhub_namespace_id" {
  description = "The full resource ID of the Event Hub namespace"
  value       = azurerm_eventhub_namespace.central_ns.id
}

output "central_eventhub_name" {
  description = "The name of the Event Hub used for log forwarding"
  value       = azurerm_eventhub.central_logs.name
}

output "central_eventhub_id" {
  description = "The ID of the Event Hub used for log forwarding"
  value       = azurerm_eventhub.central_logs.id
}

output "central_eventhub_auth_rule_id" {
  description = "Authorization rule ID for sending to the central Event Hub"
  value       = azurerm_eventhub_namespace_authorization_rule.send_rule.id
}

output "central_logging_rg" {
  description = "The resource group name where central logging resources live"
  value       = azurerm_resource_group.logging.name
}

# output "combined_dcr_id" {
#   value = azurerm_monitor_data_collection_rule.windows_dcr.id
# }

# output "network_watcher_name" {
#   value = azurerm_network_watcher.default.name
# }

# output "network_watcher_rg" {
#   value = azurerm_network_watcher.default.resource_group_name
# }

# output "network_watcher_location" {
#   value = azurerm_network_watcher.default.location
# }

output "workspace_id" {
  value = azurerm_log_analytics_workspace.central_law.workspace_id
}

output "central_log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.central_law.id
}

