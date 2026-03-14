# HIPAA-Compliant 6-Year Log Archive Module (Azure)

This Terraform module creates HIPAA-compliant log archival infrastructure with:
- **Immutable storage** (WORM policy): 6-year retention, locked state
- **Lifecycle transitions**: Hot (0-90d) → Cool (90-365d) → Archive (365d+)
- **Dual-destination logging**: Archive storage + Log Analytics Workspace
- **Comprehensive log collection**: Entra ID, Activity Log, NSG Flow Logs, Windows VM Event Logs

## Usage

```hcl
module "hipaa_log_archive" {
  source = "../modules/hipaa-log-archive"

  storage_account_name       = "acme-health-archive-prod"
  resource_group_name        = "rg-logging-archive"
  location                   = "eastus"
  log_analytics_workspace_id = data.terraform_remote_state.logging.outputs.law_id
  network_watcher_name       = "NetworkWatcher_eastus"
  network_watcher_rg         = "NetworkWatcherRG"

  nsg_ids = {
    "main-nsg"     = data.terraform_remote_state.main.outputs.main_nsg_id
    "firewall-nsg" = data.terraform_remote_state.firewall.outputs.firewall_nsg_id
  }

  vm_ids = [
    data.terraform_remote_state.main.outputs.vm_id_1,
    data.terraform_remote_state.main.outputs.vm_id_2
  ]

  tags = {
    environment         = "production"
    owner               = "it-security"
    managed-by          = "terraform"
    data-classification = "phi"
    cost-center         = "it"
    compliance-scope    = "hipaa-soc2-hitrust"
  }
}
```

## Requirements

- Terraform >= 1.0
- Azure provider >= 4.0
- Existing Log Analytics Workspace
- Existing Network Watcher (one per region)
- Resource group for storage account

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `storage_account_name` | string | - | Storage account name (3-24 lowercase alphanumeric) |
| `resource_group_name` | string | - | Resource group for storage account |
| `location` | string | - | Azure region |
| `tags` | map(string) | - | Required tags (6 keys) |
| `log_analytics_workspace_id` | string | - | Log Analytics Workspace ID |
| `nsg_ids` | map(string) | `{}` | Map of NSG names to IDs |
| `vm_ids` | list(string) | `[]` | List of VM resource IDs |
| `network_watcher_name` | string | - | Network Watcher name |
| `network_watcher_rg` | string | - | Network Watcher resource group |

## Outputs

| Name | Description |
|------|-------------|
| `storage_account_id` | Storage account resource ID |
| `storage_account_name` | Storage account name |
| `dcr_id` | Data Collection Rule ID (if VMs provided) |
| `containers` | Map of container names |

## Compliance

- **HIPAA §164.312(b)**: Audit controls (all log categories captured)
- **HIPAA §164.308(a)(1)(ii)(D)**: 6-year retention requirement
- **HIPAA §164.312(c)(1)**: Integrity controls (immutable storage, WORM policy)
- **CKV_AZURE_35**: TLS 1.2 minimum
- **CKV_AZURE_190**: No public access
- **CKV_AZURE_59**: Soft delete enabled

## Verification

```bash
# Check for log blobs (24-48hr after deployment)
az storage blob list \
  --account-name acme-health-archive-prod \
  --container-name entra-logs \
  --auth-mode login \
  --output table

# Verify lifecycle policy
az storage account management-policy show \
  --account-name acme-health-archive-prod \
  --resource-group rg-logging-archive

# Verify immutability policy
az storage account show \
  --name acme-health-archive-prod \
  --resource-group rg-logging-archive \
  --query immutabilityPolicy
```
