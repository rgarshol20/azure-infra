# logging — Azure Logging Subscription

Manages the centralized security logging hub for all AcmeHealth Group subscriptions: Log Analytics workspace, EventHub ingestion pipeline, HIPAA-compliant 6-year immutable archive storage, and security alerting.

**Subscription:** Logging 
**Region:** West US (`westus`)
**Backend:** `acme-health-terraform-state` / container `terraform-state` / `logging.terraform.tfstate`

---

## What's Deployed

### Central Log Analytics Workspace (`sec_law.tf`)
- **`acme-health-logging-law-central`** — PerGB2018, 365-day retention
- Primary SIEM destination for all subscription diagnostic settings
- Receives: Entra ID sign-in/audit logs, NSG flow logs, VM event logs, activity logs, syslog

### EventHub Ingestion Pipeline (`sec_law.tf`)
- **Namespace:** `acme-health-logging-central-eh` (Standard SKU)
- **EventHub:** `acme-health-logging-central-logs` (2 partitions, 7-day retention)
- **Auth rule:** `acme-health-logging-send-logs` (Send-only, used by cross-subscription diagnostic settings)
- Central DCR: `central-dcr` (syslog + Windows events → central LAW)

### HIPAA Log Archive Storage (`sec_archive.tf`)
- **Storage account:** `acme-health-archive-prod` (GRS, Standard, StorageV2)
  - TLS 1.2, public access blocked, network ACL deny with admin + cloudpc IP allowlist
  - Soft delete: 14-day blob + container
  - Lifecycle: Hot → Cool (90 days) → Archive (365 days); no delete rule (6-year minimum)
- **Containers (all with WORM immutability, locked = true, 2190 days / 6 years):**
  - `entra-logs`, `activity-logs`, `nsg-flow-logs`, `vm-logs`, `github-audit-logs`
- **Warning:** Locked WORM containers cannot be deleted until 2190 days expire. `terraform destroy` will fail.

### Security Alerts (`sec_alerts.tf`)
Action group `ag-critical-security` routes to `roryg@acme-health.com`. Active alerts:

| Alert | Trigger |
|---|---|
| `alert-breakglass-signin` | Any break glass account sign-in |
| `alert-global-admin-assigned` | Global Admin role granted |
| `alert-ca-policy-changed` | Conditional Access policy modified |
| `alert-mfa-method-changed` | MFA method registration changed |
| `alert-risky-signin` | High-risk sign-in detected |
| `alert-keyvault-access-denied` | Key Vault access denied event |
| `alert-nsg-modified` | NSG rule change |
| `alert-storage-public-access` | Storage public access enabled |
| `alert-vm-deallocated` | Production VM deallocated |
| `alert-backup-job-failed` | Backup job failure |

### Defender (`sec_defender.tf`)
- Subscription-scoped Defender plans for the Logging subscription

---

## Cross-Subscription Integration

All other subscriptions ship logs here:
- **Diagnostic settings** point to `acme-health-logging-law-central` (LAW ID) and `acme-health-logging-central-logs` (EventHub) via the `central_eventhub_auth_rule_id` output
- **NSG flow logs** from each subscription point to `acme-health-archive-prod` for blob archival
- **VM DCR associations** use `central-dcr` for syslog and Windows event forwarding

Key outputs consumed by other modules:
- `central_eventhub_name`, `central_eventhub_namespace_name`, `central_eventhub_auth_rule_id`
- `archive_storage_account_id`, `archive_storage_account_name`
- `central_law_id`, `central_law_workspace_id`

---

## How to Apply

```bash
cd logging/
terraform init
terraform plan
terraform apply
```

CI/CD: `.github/workflows/deploy-logging.yml` (Terraform 1.9.8).

**If the state is locked:**
```bash
az storage blob lease break \
  --blob-name logging.terraform.tfstate \
  --container-name terraform-state \
  --account-name acme-health-terraform-state \
  --auth-mode login \
  --subscription <subscription id>
```

---

## Notes

- The WORM immutability policies on archive containers are **permanently locked** — do not attempt to reduce retention or delete containers
- Network Watcher must exist in the logging region before flow log resources can be created (`NetworkWatcher_${var.location}`)
- Apply logging before other subscriptions that depend on its outputs

---
_Last pipeline verification: 2026-03-07 (run 2)_


<!-- smoke: 2026-03-09 -->

<!-- smoke: 2026-03-09 -->
