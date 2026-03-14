# Data Collection Rule for Windows VM Event Logs (System, Security, Application)
resource "azurerm_monitor_data_collection_rule" "windows_archive" {
  count = length(var.vm_ids) > 0 ? 1 : 0 # Only create if VMs exist

  name                = var.dcr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  # Destinations: Both Log Analytics Workspace (hot querying) and Storage Account (archive)
  destinations {
    log_analytics {
      workspace_resource_id = var.log_analytics_workspace_id
      name                  = "law-destination"
    }

    storage_blob {
      storage_account_id = azurerm_storage_account.archive.id
      container_name     = azurerm_storage_container.vm_logs.name
      name               = "storage-destination"
    }
  }

  # Data Sources: Windows Event Logs (System, Security, Application)
  data_sources {
    windows_event_log {
      name    = "windows-system-logs"
      streams = ["Microsoft-Event"]
      x_path_queries = [
        "System!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=0)]]"
      ]
    }

    windows_event_log {
      name    = "windows-security-logs"
      streams = ["Microsoft-Event"]
      x_path_queries = [
        "Security!*"
      ]
    }

    windows_event_log {
      name    = "windows-application-logs"
      streams = ["Microsoft-Event"]
      x_path_queries = [
        "Application!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=0)]]"
      ]
    }
  }

  # Data Flows: Route to both destinations
  data_flow {
    streams      = ["Microsoft-Event"]
    destinations = ["law-destination", "storage-destination"]
  }
}

# Data Collection Rule Associations - Link VMs to DCR
resource "azurerm_monitor_data_collection_rule_association" "vm_archive" {
  for_each = toset(var.vm_ids)

  name                    = "dcra-${basename(each.value)}"
  target_resource_id      = each.value
  data_collection_rule_id = azurerm_monitor_data_collection_rule.windows_archive[0].id

  depends_on = [azurerm_monitor_data_collection_rule.windows_archive]
}
