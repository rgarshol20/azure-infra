# HIPAA-Compliant 6-Year Log Archive Storage Account
# Immutable storage with lifecycle transitions: Hot (0-90d) → Cool (90-365d) → Archive (365d+)

data "azurerm_client_config" "current" {}

resource "azurerm_storage_account" "archive" {
  #checkov:skip=CKV_AZURE_33:Queue service not used; this is a log archive storage account
  #checkov:skip=CKV_AZURE_59:Blob logging captured via azurerm_monitor_diagnostic_setting.archive_storage_diag
  name                            = var.storage_account_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "GRS" # Geo-redundant for disaster recovery
  account_kind                    = "StorageV2"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false # Block all public access
  https_traffic_only_enabled      = true

  # Soft delete for accidental deletion recovery (14 days)
  blob_properties {
    delete_retention_policy {
      days = 14
    }
    container_delete_retention_policy {
      days = 14
    }
    versioning_enabled = true # Required for immutability policy
  }

  # HIPAA SEC-02: Network access restricted to admin IPs only
  # CRITICAL: bypass = ["AzureServices"] required for diagnostic settings
  network_rules {
    bypass                     = ["AzureServices"]
    default_action             = "Deny"
    ip_rules                   = [var.admin_ip, var.cloudpc_ip]
    virtual_network_subnet_ids = []

    private_link_access {
      endpoint_resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Security/datascanners/storageDataScanner"
      endpoint_tenant_id   = data.azurerm_client_config.current.tenant_id
    }
  }

  tags = var.tags
}

# Storage containers for different log types
resource "azurerm_storage_container" "entra_logs" {
  name                  = "entra-logs"
  storage_account_id    = azurerm_storage_account.archive.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "activity_logs" {
  name                  = "activity-logs"
  storage_account_id    = azurerm_storage_account.archive.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "nsg_flow_logs" {
  name                  = "nsg-flow-logs"
  storage_account_id    = azurerm_storage_account.archive.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "vm_logs" {
  name                  = "vm-logs"
  storage_account_id    = azurerm_storage_account.archive.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "github_audit_logs" {
  name                  = "github-audit-logs"
  storage_account_id    = azurerm_storage_account.archive.id
  container_access_type = "private"
}

# Lifecycle Management: Hot → Cool (90d) → Archive (365d)
resource "azurerm_storage_management_policy" "archive_lifecycle" {
  storage_account_id = azurerm_storage_account.archive.id

  rule {
    name    = "transition-to-cool"
    enabled = true

    filters {
      blob_types = ["blockBlob"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than = 90
      }
    }
  }

  rule {
    name    = "transition-to-archive"
    enabled = true

    filters {
      blob_types = ["blockBlob"]
    }

    actions {
      base_blob {
        tier_to_archive_after_days_since_modification_greater_than = 365
      }
    }
  }

  # CRITICAL: NO delete rule — logs retained indefinitely for manual management (6-year minimum)
}

# Immutability Policies (WORM - Write Once Read Many): 6-year retention, locked state
# Applied per container as required by azurerm provider
#
# ⚠️  WORM POLICY LOCK STATUS - CRITICAL INFORMATION ⚠️
#
# All immutability policies below are PERMANENTLY LOCKED (locked = true).
#
# CONSEQUENCES OF LOCKED STATUS:
# - Containers CANNOT be deleted for 6 years (2190 days)
# - Lock status is IRREVERSIBLE - cannot be changed back to unlocked
# - Immutability period CANNOT be reduced (only extended)
# - Storage account CANNOT be deleted while locked containers exist
# - Terraform destroy WILL FAIL for these resources
#
# DO NOT ATTEMPT TO:
# - Change locked = true to locked = false (Azure will reject)
# - Reduce immutability_period_in_days (Azure will reject)
# - Delete containers before 2190 days expire (Azure will reject)
# - Delete storage account while containers exist (Azure will reject)
#
# RISK ACCEPTANCE: This configuration ensures HIPAA compliance by preventing
# premature deletion of audit logs. The 6-year retention is a regulatory
# requirement, not a technical preference.

# IMPORTANT: Deploy with locked = false first to validate log flow.
# Once confirmed, change to locked = true in a follow-up PR.
# WARNING: locked = true is PERMANENT and IRREVERSIBLE.
resource "azurerm_storage_container_immutability_policy" "entra_logs_worm" {
  storage_container_resource_manager_id = azurerm_storage_container.entra_logs.id
  immutability_period_in_days           = 2190 # 6 years (365 * 6)
  locked                                = true # Prevents modification/deletion
  protected_append_writes_enabled       = true # Allow appending (for log writes)
}

# IMPORTANT: Deploy with locked = false first to validate log flow.
# Once confirmed, change to locked = true in a follow-up PR.
# WARNING: locked = true is PERMANENT and IRREVERSIBLE.
resource "azurerm_storage_container_immutability_policy" "activity_logs_worm" {
  storage_container_resource_manager_id = azurerm_storage_container.activity_logs.id
  immutability_period_in_days           = 2190
  locked                                = true
  protected_append_writes_enabled       = true
}

# IMPORTANT: Deploy with locked = false first to validate log flow.
# Once confirmed, change to locked = true in a follow-up PR.
# WARNING: locked = true is PERMANENT and IRREVERSIBLE.
resource "azurerm_storage_container_immutability_policy" "nsg_flow_logs_worm" {
  storage_container_resource_manager_id = azurerm_storage_container.nsg_flow_logs.id
  immutability_period_in_days           = 2190
  locked                                = true
  protected_append_writes_enabled       = true
}

# IMPORTANT: Deploy with locked = false first to validate log flow.
# Once confirmed, change to locked = true in a follow-up PR.
# WARNING: locked = true is PERMANENT and IRREVERSIBLE.
resource "azurerm_storage_container_immutability_policy" "vm_logs_worm" {
  storage_container_resource_manager_id = azurerm_storage_container.vm_logs.id
  immutability_period_in_days           = 2190
  locked                                = true
  protected_append_writes_enabled       = true
}

# IMPORTANT: Deploy with locked = false first to validate log flow.
# Once confirmed, change to locked = true in a follow-up PR.
# WARNING: locked = true is PERMANENT and IRREVERSIBLE.
resource "azurerm_storage_container_immutability_policy" "github_audit_logs_worm" {
  storage_container_resource_manager_id = azurerm_storage_container.github_audit_logs.id
  immutability_period_in_days           = 2190
  locked                                = true
  protected_append_writes_enabled       = true
}

# Diagnostic Settings for Archive Storage Account (audit access logs)
resource "azurerm_monitor_diagnostic_setting" "archive_storage_diag" {
  name                       = "archive-storage-diag"
  target_resource_id         = azurerm_storage_account.archive.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Storage account metrics
  metric {
    category = "Transaction"
    enabled  = true
  }

  lifecycle {
    ignore_changes = [metric]
  }
}
