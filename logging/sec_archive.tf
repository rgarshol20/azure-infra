# HIPAA-Compliant 6-Year Log Archive
# Archive storage independent of SIEM (Arctic Wolf)
# Immutable storage with Hot→Cool→Archive lifecycle transitions

# Remote state data sources for environment NSG and VM IDs





# Resource Group for Archive Storage
resource "azurerm_resource_group" "archive" {
  provider = azurerm.logging
  name     = "rg-logging-archive"
  location = var.location

  tags = local.required_tags
}

# HIPAA Log Archive Module
module "hipaa_log_archive" {
  source = "../modules/hipaa-log-archive"

  providers = {
    azurerm = azurerm.logging
  }

  storage_account_name       = "acme-health-archive-prod"
  resource_group_name        = azurerm_resource_group.archive.name
  location                   = azurerm_resource_group.archive.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.central_law.id
  admin_ip                   = var.admin_ip
  cloudpc_ip                 = var.cloudpc_ip

  # Network Watcher (one per region, typically auto-created by Azure)
  # If NetworkWatcher_<region> doesn't exist, create it first or update the name
  network_watcher_name = "NetworkWatcher_${var.location}"
  network_watcher_rg   = "NetworkWatcherRG"

  # NSG Flow Logs - NOT created centrally (cross-subscription not supported)
  # Flow logs are created in each environment's terraform and point to this archive storage
  nsg_ids = {}

  # Windows VM IDs for Data Collection Rule - Empty (DCR associations managed in environment modules)
  vm_ids = []

  # Diagnostic setting names (using module defaults, can override)
  entra_diagnostic_setting_name    = "acme-health-archive-entra-diag"
  activity_diagnostic_setting_name = "acme-health-archive-activity-diag"
  dcr_name                         = "acme-health-archive-dcr-windows"

  tags = merge(local.required_tags, {
    Name    = "HIPAA Log Archive Storage"
    Purpose = "6-year log retention for HIPAA compliance"
  })

  depends_on = [azurerm_resource_group.archive]
}

# RBAC: allow ops-automation GitHub Actions workflow to manage network rules
# on acme-health-archive-prod so it can add/remove the runner's outbound IP just-in-time
# before and after the daily audit log upload.
#
# Storage Account Contributor is required for Microsoft.Storage/storageAccounts/write
# (network rule management). Scoped to the single storage account, not the RG.
#
# Service principal: ops-automation GitHub Actions OIDC app registration
# Object ID sourced from: az ad sp show --id <AZURE_CLIENT_ID> --query id -o tsv
resource "azurerm_role_assignment" "ops_automation_archive_contributor" {
  provider             = azurerm.logging
  scope                = module.hipaa_log_archive.storage_account_id
  role_definition_name = "Storage Account Contributor"
  principal_id         = "a373da7a-cb84-4520-b9a1-3040be9a1db6"

  description = "ops-automation GitHub Actions — network rule management for just-in-time runner IP allowlisting"
}

# Storage Blob Data Contributor — required for az storage blob upload --auth-mode login
# (the actual audit log file write to github-audit-logs container)
resource "azurerm_role_assignment" "ops_automation_blob_contributor" {
  provider             = azurerm.logging
  scope                = module.hipaa_log_archive.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = "a373da7a-cb84-4520-b9a1-3040be9a1db6"

  description = "ops-automation GitHub Actions — blob upload for daily GitHub audit log export"
}

# Outputs for archive storage
output "archive_storage_account_id" {
  description = "Resource ID of the HIPAA log archive storage account"
  value       = module.hipaa_log_archive.storage_account_id
}

output "archive_storage_account_name" {
  description = "Name of the HIPAA log archive storage account"
  value       = module.hipaa_log_archive.storage_account_name
}

output "archive_dcr_id" {
  description = "Resource ID of the Windows VM Data Collection Rule (if VMs provided)"
  value       = module.hipaa_log_archive.dcr_id
}
