
resource "azurerm_log_analytics_workspace" "local_law" {
  provider            = azurerm.firewall
  name                = "acme-health-firewall-law"
  location            = var.location
  resource_group_name = azurerm_resource_group.logging.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.required_tags
}

resource "azurerm_eventhub_namespace_authorization_rule" "send_rule" {
  provider            = azurerm.logging
  name                = "acme-health-firewall-namespace-auth-rule"
  namespace_name      = module.remote_state.logging.outputs.central_eventhub_namespace_name
  resource_group_name = module.remote_state.logging.outputs.central_logging_rg

  listen = false
  send   = true
  manage = false
}

# Refactored to use diagnostic-settings module (dual-destination, no EventHub)
module "diag_kv_firewall" {
  source = "../modules/diagnostic-settings"

  diagnostic_setting_name    = "diag-kv-firewall"
  target_resource_id         = module.key_vault.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.local_law.id
  storage_account_id         = module.remote_state.logging.outputs.archive_storage_account_id

  log_categories    = ["AuditEvent"]
  metric_categories = ["AllMetrics"]
}

resource "azurerm_monitor_data_collection_endpoint" "default" {
  provider            = azurerm.firewall
  name                = "dce-firewall"
  location            = var.location
  resource_group_name = azurerm_resource_group.logging.name

  tags = local.required_tags
}

resource "azurerm_monitor_data_collection_rule" "windows_dcr" {
  provider                    = azurerm.firewall
  name                        = "windows-dcr"
  location                    = azurerm_resource_group.logging.location
  resource_group_name         = azurerm_resource_group.logging.name
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.default.id
  kind                        = "Windows"
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
      name           = "win-events"
      streams        = ["Microsoft-Event"] # <- correct
      x_path_queries = ["System!*", "Application!*", "Security!*"]
    }
  }

  data_flow {
    streams      = ["Microsoft-Event"]
    destinations = ["default-workspace", "archive-storage"] # Dual-destination: LAW + archive
  }
}


# Refactored to use diagnostic-settings module (dual-destination, no EventHub)
module "diag_nsg_public_firewall" {
  source = "../modules/diagnostic-settings"

  diagnostic_setting_name    = "diag-nsg-public-firewall"
  target_resource_id         = azurerm_network_security_group.public_nsg.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.local_law.id
  storage_account_id         = module.remote_state.logging.outputs.archive_storage_account_id

  log_categories    = ["NetworkSecurityGroupEvent", "NetworkSecurityGroupRuleCounter"]
  metric_categories = []
}

module "diag_nsg_private_firewall" {
  source = "../modules/diagnostic-settings"

  diagnostic_setting_name    = "diag-nsg-private-firewall"
  target_resource_id         = azurerm_network_security_group.private_nsg.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.local_law.id
  storage_account_id         = module.remote_state.logging.outputs.archive_storage_account_id

  log_categories    = ["NetworkSecurityGroupEvent", "NetworkSecurityGroupRuleCounter"]
  metric_categories = []
}

module "diag_nsg_mgmt_firewall" {
  source = "../modules/diagnostic-settings"

  diagnostic_setting_name    = "diag-nsg-mgmt-firewall"
  target_resource_id         = azurerm_network_security_group.mgmt_nsg.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.local_law.id
  storage_account_id         = module.remote_state.logging.outputs.archive_storage_account_id

  log_categories    = ["NetworkSecurityGroupEvent", "NetworkSecurityGroupRuleCounter"]
  metric_categories = []
}

# Twingate and AD NSG diagnostic settings - see module calls at end of file


# Ensure Network Watcher exists in the region
resource "azurerm_network_watcher" "westus" {
  provider            = azurerm.firewall
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
  provider             = azurerm.firewall
  name                 = "flowlog-vnet-firewall"
  resource_group_name  = "NetworkWatcherRG"
  location             = azurerm_network_watcher.westus.location
  network_watcher_name = azurerm_network_watcher.westus.name
  tags                 = local.required_tags

  # 👇 VNet flow logs: point at the VNet (NOT an NSG)
  target_resource_id = azurerm_virtual_network.firewall.id

  storage_account_id = module.remote_state.logging.outputs.archive_storage_account_id

  enabled = true
  version = 2 # if supported in your region; else 1

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

resource "azurerm_monitor_data_collection_rule" "syslog_dcr" {
  provider                    = azurerm.firewall
  name                        = "syslog-dcr"
  location                    = azurerm_resource_group.logging.location
  resource_group_name         = azurerm_resource_group.logging.name
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.default.id
  kind                        = "Linux"
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
    syslog {
      name    = "syslog-default"
      streams = ["Microsoft-Syslog"]
      facility_names = [
        "auth", "authpriv", "daemon", "kern", "syslog",
        "local0", "local1", "local2", "local3",
        "local4", "local5", "local6", "local7",
      ]
      log_levels = ["Info", "Notice", "Warning", "Error", "Critical", "Alert", "Emergency"]
    }
  }

  data_flow {
    streams      = ["Microsoft-Syslog"]
    destinations = ["default-workspace", "archive-storage"] # Dual-destination: LAW + archive (Palo Alto syslog)
  }
}

# Activity Log diagnostic settings (subscription-scoped)
resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  provider           = azurerm.firewall
  name               = "firewall-activity-log-diag"
  target_resource_id = "/subscriptions/${var.firewall_subscription_id}"

  log_analytics_workspace_id     = azurerm_log_analytics_workspace.local_law.id
  eventhub_name                  = module.remote_state.logging.outputs.central_eventhub_name
  eventhub_authorization_rule_id = module.remote_state.logging.outputs.central_eventhub_auth_rule_id
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

# Diagnostic settings for Twingate NSG
module "diag_nsg_twingate" {
  source = "../modules/diagnostic-settings"

  diagnostic_setting_name    = "diag-nsg-twingate"
  target_resource_id         = azurerm_network_security_group.twingate_nsg.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.local_law.id
  storage_account_id         = module.remote_state.logging.outputs.archive_storage_account_id

  log_categories    = ["NetworkSecurityGroupEvent", "NetworkSecurityGroupRuleCounter"]
  metric_categories = []
}

# Diagnostic settings for AD NSG
module "diag_nsg_ad_firewall" {
  source = "../modules/diagnostic-settings"

  diagnostic_setting_name    = "diag-nsg-ad-firewall"
  target_resource_id         = azurerm_network_security_group.ad_nsg.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.local_law.id
  storage_account_id         = module.remote_state.logging.outputs.archive_storage_account_id

  log_categories    = ["NetworkSecurityGroupEvent", "NetworkSecurityGroupRuleCounter"]
  metric_categories = []
}
