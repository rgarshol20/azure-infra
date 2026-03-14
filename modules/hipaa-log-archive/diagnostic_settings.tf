# Entra ID (Azure AD) Diagnostic Settings - ALL 9 log categories
resource "azurerm_monitor_aad_diagnostic_setting" "entra_archive" {
  name                       = var.entra_diagnostic_setting_name
  storage_account_id         = azurerm_storage_account.archive.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # CRITICAL: All 9 Entra ID log categories must be enabled
  enabled_log {
    category = "SignInLogs"
  }

  enabled_log {
    category = "AuditLogs"
  }

  enabled_log {
    category = "NonInteractiveUserSignInLogs"
  }

  enabled_log {
    category = "ServicePrincipalSignInLogs"
  }

  enabled_log {
    category = "ManagedIdentitySignInLogs"
  }

  enabled_log {
    category = "ProvisioningLogs"
  }

  enabled_log {
    category = "ADFSSignInLogs"
  }

  enabled_log {
    category = "RiskyUsers"
  }

  enabled_log {
    category = "UserRiskEvents"
  }
}

# Activity Log Diagnostic Settings - Subscription level (Administrative, Security, Alert, Policy)
data "azurerm_subscription" "current" {}

# Get Log Analytics Workspace details for Traffic Analytics
data "azurerm_log_analytics_workspace" "central" {
  name                = split("/", var.log_analytics_workspace_id)[8]
  resource_group_name = split("/", var.log_analytics_workspace_id)[4]
}

resource "azurerm_monitor_diagnostic_setting" "activity_archive" {
  name                       = var.activity_diagnostic_setting_name
  target_resource_id         = data.azurerm_subscription.current.id
  storage_account_id         = azurerm_storage_account.archive.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # CRITICAL: 4 Activity Log categories required
  enabled_log {
    category = "Administrative"
  }

  enabled_log {
    category = "Security"
  }

  enabled_log {
    category = "Alert"
  }

  enabled_log {
    category = "Policy"
  }
}

# NSG Flow Logs - Version 2 with Traffic Analytics
resource "azurerm_network_watcher_flow_log" "nsg_archive" {
  #checkov:skip=CKV_AZURE_12:Retention managed by storage account lifecycle policy; built-in retention_days not used
  for_each = var.nsg_ids

  name                      = "flowlog-archive-${each.key}"
  network_watcher_name      = var.network_watcher_name
  resource_group_name       = var.network_watcher_rg
  network_security_group_id = each.value
  storage_account_id        = azurerm_storage_account.archive.id
  enabled                   = true
  version                   = 2 # Version 2 includes throughput metrics

  # CRITICAL: Disable built-in retention - use storage account lifecycle policy instead
  retention_policy {
    enabled = false
    days    = 0
  }

  # Traffic Analytics for hot querying and visualization
  traffic_analytics {
    enabled               = true
    workspace_id          = data.azurerm_log_analytics_workspace.central.workspace_id
    workspace_region      = var.location
    workspace_resource_id = var.log_analytics_workspace_id
    interval_in_minutes   = 10
  }
}
