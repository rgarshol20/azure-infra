# Diagnostic Settings Module

Reusable Terraform module for creating Azure Monitor diagnostic settings with dual-destination logging (Log Analytics Workspace + Archive Storage) for HIPAA compliance.

## Features

- **Dual-destination logging:** Routes logs to both LAW (operational queries) and archive storage (6-year retention)
- **Dynamic log categories:** Supports any resource type's log categories via variable
- **Input validation:** Prevents empty log category lists and validates Azure resource ID formats
- **Portfolio-quality:** DRY principle, reusable across all environments and resource types

## Usage

### Recovery Services Vault Example

```hcl
module "diag_rsv_prod" {
  source = "../../modules/diagnostic-settings"

  diagnostic_setting_name    = "diag-rsv-prod"
  target_resource_id         = azurerm_recovery_services_vault.rsv.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.local_law.id
  storage_account_id         = data.terraform_remote_state.logging.outputs.archive_storage_account_id

  log_categories = [
    "CoreAzureBackup",
    "AddonAzureBackupJobs",
    "AddonAzureBackupPolicy",
    "AddonAzureBackupStorage",
    "AddonAzureBackupProtectedInstance",
    "AddonAzureBackupAlerts"
  ]

  metric_categories = ["AllMetrics"]
}
```

### Key Vault Example

```hcl
module "diag_kv_prod" {
  source = "../../modules/diagnostic-settings"

  diagnostic_setting_name    = "diag-kv-prod"
  target_resource_id         = azurerm_key_vault.hipaa_kv.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.local_law.id
  storage_account_id         = data.terraform_remote_state.logging.outputs.archive_storage_account_id

  log_categories    = ["AuditEvent"]
  metric_categories = ["AllMetrics"]
}
```

### Network Security Group Example

```hcl
module "diag_nsg_servers" {
  source = "../../modules/diagnostic-settings"

  diagnostic_setting_name    = "diag-nsg-servers"
  target_resource_id         = azurerm_network_security_group.nsg_servers.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.local_law.id
  storage_account_id         = data.terraform_remote_state.logging.outputs.archive_storage_account_id

  log_categories = [
    "NetworkSecurityGroupEvent",
    "NetworkSecurityGroupRuleCounter"
  ]

  metric_categories = []  # NSGs don't support metrics
}
```

### Storage Account Blob Service Example

```hcl
module "diag_storage_blob_prod" {
  source = "../../modules/diagnostic-settings"

  diagnostic_setting_name    = "diag-storage-blob-prod"
  target_resource_id         = "${azurerm_storage_account.encrypted_storage.id}/blobServices/default"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.local_law.id
  storage_account_id         = data.terraform_remote_state.logging.outputs.archive_storage_account_id

  log_categories    = ["StorageRead", "StorageWrite", "StorageDelete"]
  metric_categories = ["Transaction", "Capacity"]
}
```

## Discovering Log Categories

**CRITICAL:** Log category names vary by resource type. Using incorrect names causes silent failures (diagnostic setting creates successfully but no logs delivered).

**Before applying, verify categories:**

```bash
# Recovery Services Vault
az monitor diagnostic-settings categories list \
  --resource $(az backup vault list --query "[0].id" -o tsv) \
  --output table

# Key Vault
az monitor diagnostic-settings categories list \
  --resource $(az keyvault list --query "[0].id" -o tsv) \
  --output table

# Network Security Group
az monitor diagnostic-settings categories list \
  --resource $(az network nsg list --query "[0].id" -o tsv) \
  --output table

# Storage Account (blob service)
az monitor diagnostic-settings categories list \
  --resource "<storage-account-id>/blobServices/default" \
  --output table
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `diagnostic_setting_name` | string | - | Name for the diagnostic setting resource (1-260 characters) |
| `target_resource_id` | string | - | Resource ID to attach diagnostic settings to |
| `log_analytics_workspace_id` | string | - | Log Analytics Workspace ID for operational queries |
| `storage_account_id` | string | - | Archive storage account ID for 6-year HIPAA retention |
| `log_categories` | list(string) | - | List of log categories to enable (minimum 1 required) |
| `metric_categories` | list(string) | `[]` | List of metric categories to enable (set to [] if unsupported) |

## Outputs

| Name | Description |
|------|-------------|
| `diagnostic_setting_id` | Resource ID of the diagnostic setting |
| `diagnostic_setting_name` | Name of the diagnostic setting |

## Requirements

- Terraform >= 1.0
- Azure provider >= 4.0
- Existing Log Analytics Workspace
- Existing archive storage account (HIPAA-compliant with WORM immutability)

## Compliance

- **HIPAA §164.312(b):** Audit controls (all log categories captured)
- **HIPAA §164.308(a)(1)(ii)(D):** 6-year retention requirement (archive storage)
- **Dual-destination pattern:** Operational (LAW) + compliance (archive storage)

## Verification

```bash
# Wait 10-15 minutes after apply, then query LAW:
az monitor log-analytics query \
  --workspace <law-id> \
  --analytics-query "AzureDiagnostics | where ResourceId contains '<resource-name>' | take 10" \
  --output table

# Wait 24-48 hours, then check archive storage:
az storage blob list \
  --account-name <archive-storage-name> \
  --container-name <container> \
  --auth-mode login \
  --output table
```

## Portfolio Notes

This module demonstrates:
- **DRY principle:** Single source of truth for diagnostic settings across 6 environments
- **Input validation:** Terraform variable validation blocks prevent misconfiguration
- **Dynamic blocks:** `for_each` pattern supports varying log categories per resource type
- **HIPAA compliance:** Dual-destination pattern meets audit trail requirements
- **Portability:** No hardcoded IDs — uses remote state outputs and resource references
