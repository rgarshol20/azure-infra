
resource "azurerm_log_analytics_workspace" "local_law" {
  provider            = azurerm.dashboard
  name                = "acme-health-dashboard-law"
  location            = var.location
  resource_group_name = azurerm_resource_group.logging.name
  sku                 = "PerGB2018"
  retention_in_days   = 730 # azurerm provider max; archive retention configured via Azure Portal

  tags = local.required_tags
}

resource "azurerm_eventhub_namespace_authorization_rule" "send_rule" {
  provider            = azurerm.logging
  name                = "acme-health-dashboard-namespace-auth-rule"
  namespace_name      = module.remote_state.logging.outputs.central_eventhub_namespace_name
  resource_group_name = module.remote_state.logging.outputs.central_logging_rg

  listen = false
  send   = true
  manage = false
}

# Refactored to use diagnostic-settings module (dual-destination, no EventHub)
module "diag_kv_dashboard" {
  source = "../modules/diagnostic-settings"

  diagnostic_setting_name    = "diag-kv-dashboard"
  target_resource_id         = module.key_vault.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.local_law.id
  storage_account_id         = module.remote_state.logging.outputs.archive_storage_account_id

  log_categories    = ["AuditEvent"]
  metric_categories = ["AllMetrics"]
}

resource "azurerm_monitor_data_collection_endpoint" "default" {
  provider            = azurerm.dashboard
  name                = "dce-dashboard"
  location            = var.location
  resource_group_name = azurerm_resource_group.logging.name

  tags = local.required_tags
}

resource "azurerm_monitor_data_collection_rule" "windows_dcr" {
  provider                    = azurerm.dashboard
  name                        = "windows-dcr"
  location                    = azurerm_resource_group.logging.location
  resource_group_name         = azurerm_resource_group.logging.name
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.default.id
  kind                        = "Windows" # explicit; helps validation
  tags                        = local.required_tags

  destinations {
    log_analytics {
      name                  = "default-workspace"
      workspace_resource_id = azurerm_log_analytics_workspace.local_law.id
    }

    storage_blob {
      storage_account_id = module.remote_state.logging.outputs.archive_storage_account_id
      container_name     = "vm-logs"
      name               = "archive-storage"
    }
  }

  data_sources {
    windows_event_log {
      name    = "win-events"
      streams = ["Microsoft-Event"] # <- FIX
      x_path_queries = [
        "Security!*", # all Security events
        "System!*",
        "Application!*"
      ]
    }
  }

  data_flow {
    streams      = ["Microsoft-Event"]                      # <- MATCH the stream
    destinations = ["default-workspace", "archive-storage"] # Dual-destination: LAW + archive
  }
}

# Refactored to use diagnostic-settings module (dual-destination, no EventHub)
module "diag_nsg_servers_dashboard" {
  source = "../modules/diagnostic-settings"

  diagnostic_setting_name    = "diag-nsg-servers-dashboard"
  target_resource_id         = azurerm_network_security_group.nsg_servers.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.local_law.id
  storage_account_id         = module.remote_state.logging.outputs.archive_storage_account_id

  log_categories    = ["NetworkSecurityGroupEvent", "NetworkSecurityGroupRuleCounter"]
  metric_categories = []
}

# NSG workers diagnostic setting - see module at end of file

# Ensure Network Watcher exists in the region
resource "azurerm_network_watcher" "westus" {
  provider            = azurerm.dashboard
  name                = "NetworkWatcher_westus"
  location            = "westus"
  resource_group_name = "NetworkWatcherRG"

  tags = local.required_tags
}

# Storage for flow logs (must exist; keep lifecycle rule caveat in mind)
# resource "azurerm_storage_account" "flowlogs" { ... }

# Optional: Log Analytics workspace (for traffic analytics)
# resource "azurerm_log_analytics_workspace" "law" { ... }

resource "azurerm_network_watcher_flow_log" "vnet_flow_log" {
  #checkov:skip=CKV_AZURE_12:Retention managed by storage account lifecycle policy; built-in retention_days not used
  provider             = azurerm.dashboard
  name                 = "flowlog-vnet-dashboard"
  resource_group_name  = "NetworkWatcherRG"
  location             = azurerm_network_watcher.westus.location
  network_watcher_name = azurerm_network_watcher.westus.name

  # 👇 VNet flow logs: point at the VNet (NOT an NSG)
  target_resource_id = azurerm_virtual_network.dashboard.id

  storage_account_id = module.remote_state.logging.outputs.archive_storage_account_id

  enabled = true
  version = 2 # if supported in your region; else 1

  tags = local.required_tags

  retention_policy {
    enabled = false # Let archive storage lifecycle policy handle retention
    days    = 0
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.local_law.workspace_id
    workspace_region      = azurerm_log_analytics_workspace.local_law.location
    workspace_resource_id = azurerm_log_analytics_workspace.local_law.id
  }
}





# Activity Log diagnostic settings (subscription-scoped)
resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  provider           = azurerm.dashboard
  name               = "dashboard-activity-log-diag"
  target_resource_id = "/subscriptions/${var.dashboard_subscription_id}"

  log_analytics_workspace_id     = azurerm_log_analytics_workspace.local_law.id
  eventhub_name                  = module.remote_state.logging.outputs.central_eventhub_name
  eventhub_authorization_rule_id = azurerm_eventhub_namespace_authorization_rule.send_rule.id
  storage_account_id             = module.remote_state.logging.outputs.archive_storage_account_id

  enabled_log {
    category = "Administrative"
  }
  enabled_log {
    category = "Security"
  }
  enabled_log {
    category = "Policy"
  }
  enabled_log {
    category = "Alert"
  }
}

# Diagnostic settings for dashboard nsg_workers
module "diag_nsg_workers_dashboard" {
  source = "../modules/diagnostic-settings"

  diagnostic_setting_name    = "diag-nsg-workers-dashboard"
  target_resource_id         = azurerm_network_security_group.nsg_workers.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.local_law.id
  storage_account_id         = module.remote_state.logging.outputs.archive_storage_account_id

  log_categories    = ["NetworkSecurityGroupEvent", "NetworkSecurityGroupRuleCounter"]
  metric_categories = []
}
