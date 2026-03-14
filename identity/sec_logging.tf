
resource "azurerm_log_analytics_workspace" "local_law" {
  provider            = azurerm.identity
  name                = "acme-health-identity-law"
  location            = var.location
  resource_group_name = azurerm_resource_group.logging.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.required_tags
}

resource "azurerm_eventhub_namespace_authorization_rule" "send_rule" {
  provider            = azurerm.logging
  name                = "acme-health-identity-namespace-auth-rule"
  namespace_name      = module.remote_state.logging.outputs.central_eventhub_namespace_name
  resource_group_name = module.remote_state.logging.outputs.central_logging_rg

  listen = false
  send   = true
  manage = false
}

# Refactored to use diagnostic-settings module (dual-destination, no EventHub)
module "diag_kv_identity" {
  source = "../modules/diagnostic-settings"

  diagnostic_setting_name    = "diag-kv-identity"
  target_resource_id         = module.key_vault.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.local_law.id
  storage_account_id         = module.remote_state.logging.outputs.archive_storage_account_id

  log_categories    = ["AuditEvent"]
  metric_categories = ["AllMetrics"]
}

resource "azurerm_monitor_data_collection_endpoint" "default" {
  provider            = azurerm.identity
  name                = "dce-identity"
  location            = var.location
  resource_group_name = azurerm_resource_group.logging.name

  tags = local.required_tags
}

resource "azurerm_monitor_data_collection_rule" "windows_dcr" {
  provider                    = azurerm.identity
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
module "diag_nsg_ad_identity" {
  source = "../modules/diagnostic-settings"

  diagnostic_setting_name    = "diag-nsg-ad-identity"
  target_resource_id         = azurerm_network_security_group.nsg_ad.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.local_law.id
  storage_account_id         = module.remote_state.logging.outputs.archive_storage_account_id

  log_categories    = ["NetworkSecurityGroupEvent", "NetworkSecurityGroupRuleCounter"]
  metric_categories = []
}

# Ensure Network Watcher exists in the region
resource "azurerm_network_watcher" "westus" {
  provider            = azurerm.identity
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
  provider             = azurerm.identity
  name                 = "flowlog-vnet-identity"
  resource_group_name  = "NetworkWatcherRG"
  location             = azurerm_network_watcher.westus.location
  network_watcher_name = azurerm_network_watcher.westus.name

  # 👇 VNet flow logs: point at the VNet (NOT an NSG)
  target_resource_id = azurerm_virtual_network.identity.id

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
  provider           = azurerm.identity
  name               = "identity-activity-log-diag"
  target_resource_id = "/subscriptions/${var.identity_subscription_id}"

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
