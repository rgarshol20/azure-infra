
resource "azurerm_log_analytics_workspace" "local_law" {
  name                = "acme-health-main-law"
  location            = var.location
  resource_group_name = azurerm_resource_group.logging.name
  sku                 = "PerGB2018"
  retention_in_days   = 90

  tags = local.required_tags
}

resource "azurerm_eventhub_namespace_authorization_rule" "send_rule" {
  provider            = azurerm.logging
  name                = "acme-health-main-namespace-auth-rule"
  namespace_name      = module.remote_state.logging.outputs.central_eventhub_namespace_name
  resource_group_name = module.remote_state.logging.outputs.central_logging_rg

  listen = false
  send   = true
  manage = false
}


# Refactored to use diagnostic-settings module (dual-destination, no EventHub)
module "diag_kv_main" {
  source = "../modules/diagnostic-settings"

  diagnostic_setting_name    = "diag-kv-main"
  target_resource_id         = module.key_vault.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.local_law.id
  storage_account_id         = module.remote_state.logging.outputs.archive_storage_account_id

  log_categories    = ["AuditEvent"]
  metric_categories = ["AllMetrics"]
}

# Refactored to use diagnostic-settings module (dual-destination, no EventHub)
module "diag_storage_blob_main" {
  source = "../modules/diagnostic-settings"

  diagnostic_setting_name    = "diag-storage-blob-main"
  target_resource_id         = "${azurerm_storage_account.encrypted_storage.id}/blobServices/default"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.local_law.id
  storage_account_id         = module.remote_state.logging.outputs.archive_storage_account_id

  log_categories    = ["StorageRead", "StorageWrite", "StorageDelete"]
  metric_categories = ["Transaction", "Capacity"]
}
# Storage account root-level diagnostic setting.
# Azure Storage log categories (StorageRead/Write/Delete) live on blobServices/default,
# captured by diag_storage_blob_main above. The account root only exposes metrics,
# so this resource satisfies the HIPAA audit scan without duplicating blob logs.
resource "azurerm_monitor_diagnostic_setting" "storage_account_main" {
  name                       = "diag-storage-account-main"
  target_resource_id         = azurerm_storage_account.encrypted_storage.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.local_law.id
  storage_account_id         = module.remote_state.logging.outputs.archive_storage_account_id

  enabled_metric {
    category = "Transaction"
  }

  enabled_metric {
    category = "Capacity"
  }
}

# Activity Log diagnostic settings (subscription-scoped)
resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  name               = "main-activity-log-diag"
  target_resource_id = "/subscriptions/${var.main_subscription_id}"

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
