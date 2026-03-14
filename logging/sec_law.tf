resource "azurerm_log_analytics_workspace" "central_law" {
  provider            = azurerm.logging
  name                = "acme-health-logging-law-central"
  location            = azurerm_resource_group.logging.location
  resource_group_name = azurerm_resource_group.logging.name
  sku                 = "PerGB2018"
  retention_in_days   = 730 # azurerm provider max; archive retention configured via Azure Portal

  tags = local.required_tags
}

resource "azurerm_eventhub_namespace" "central_ns" {
  #checkov:skip=CKV_AZURE_228:Local auth required for cross-subscription diagnostic settings; RBAC-only auth not compatible with all sources
  provider            = azurerm.logging
  name                = "acme-health-logging-central-eh"
  location            = azurerm_resource_group.logging.location
  resource_group_name = azurerm_resource_group.logging.name
  sku                 = "Standard"

  tags = local.required_tags
}

resource "azurerm_eventhub" "central_logs" {
  provider          = azurerm.logging
  name              = "acme-health-logging-central-logs"
  namespace_id      = azurerm_eventhub_namespace.central_ns.id
  partition_count   = 2
  message_retention = 7
}

resource "azurerm_eventhub_namespace_authorization_rule" "send_rule" {
  provider            = azurerm.logging
  name                = "acme-health-logging-send-logs"
  namespace_name      = azurerm_eventhub_namespace.central_ns.name
  resource_group_name = azurerm_resource_group.logging.name
  listen              = false
  send                = true
  manage              = false
}

# Ingestion rule must be manually set via Diagnostic Setting or programmatically via API
resource "azurerm_monitor_data_collection_rule" "central_dcr" {
  provider            = azurerm.logging
  name                = "central-dcr"
  location            = azurerm_resource_group.logging.location
  resource_group_name = azurerm_resource_group.logging.name

  destinations {
    log_analytics {
      name                  = "central-law-destination"
      workspace_resource_id = azurerm_log_analytics_workspace.central_law.id
    }
  }

  data_sources {
    syslog {
      name           = "central-syslog"
      facility_names = ["*"]
      log_levels     = ["*"]
      streams        = ["Microsoft-Syslog"]
    }
  }

  data_flow {
    streams      = ["Microsoft-Syslog"]
    destinations = ["central-law-destination"]
  }

  tags = local.required_tags
}

resource "azurerm_monitor_diagnostic_setting" "eh_ns_to_law" {
  provider                   = azurerm.logging
  name                       = "central-diag-law"
  target_resource_id         = azurerm_eventhub_namespace.central_ns.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.central_law.id

  # Enable all useful categories explicitly (Event Hubs Namespace)
  # If your provider supports category groups, you can use category_group = "allLogs".
  enabled_log {
    category = "OperationalLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}