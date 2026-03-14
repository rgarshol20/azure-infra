# =============================
# Palo Alto Firewall Logs via Event Hub
# =============================
resource "azurerm_eventhub_namespace" "palo_hub" {
  #checkov:skip=CKV_AZURE_228:Local auth required for Palo Alto syslog integration; RBAC-only auth not supported by appliance
  provider            = azurerm.firewall
  name                = "acme-health-palo-alto-logs"
  location            = azurerm_resource_group.logging.location
  resource_group_name = azurerm_resource_group.logging.name
  sku                 = "Standard"
  capacity            = 1
}

resource "azurerm_eventhub" "palo_logs" {
  provider          = azurerm.firewall
  name              = "acme-health-palo-alto-logs"
  namespace_id      = azurerm_eventhub_namespace.palo_hub.id # ✅ replacement
  partition_count   = 2
  message_retention = 7 # HIPAA: 7-day buffer protects against consumer outages (Arctic Wolf, archive pipeline)
}

module "diag_palo_hub" {
  source = "../modules/diagnostic-settings"

  diagnostic_setting_name    = "diag-palo-hub"
  target_resource_id         = azurerm_eventhub_namespace.palo_hub.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.local_law.id
  storage_account_id         = module.remote_state.logging.outputs.archive_storage_account_id

  log_categories    = ["OperationalLogs", "RuntimeAuditLogs", "ApplicationMetricsLogs"]
  metric_categories = ["AllMetrics"]
}