# dashboard — Azure Dashboard Subscription

Manages the DDE (Dynamic Desktop Environment) application delivery infrastructure: Windows Server VM, Twingate zero-trust connectors, and supporting infrastructure. This subscription is mid-decommission — the majority of legacy resources are tracked for state management and scheduled for destruction in June 2026.

**Subscription:** Dashboard / DDE (see `providers.tf` for subscription ID)
**Region:** Central US (`centralus`) for networking; other resources vary
**Backend:** `acme-health-terraform-state` / container `terraform-state` / `dashboard.terraform.tfstate`

---

## What's Deployed (Active)

### Network (`net_vnet.tf`, `net_twingate.tf`)
- Dashboard VNet + subnets
- **Twingate connectors** (resource group: `Networking`, centralus):
  - `twingate-connector-copper-tarsier` — private subnet, Linux container group
  - `twingate-connector-super-woodlouse` — private subnet, Linux container group
  - Both connectors use `ip_address_type = "Private"` with subnet delegation

### Virtual Machines
- **`bizinetazt01`** — Windows Server 2022 (Standard_E4s_v3, 500 GB data disk)
  - `encryption_at_host_enabled = true`, CMK disk encryption via `acme-health-dashboard-hipaa-disk-encryption-set`
  - AzurePolicyforWindows extension, backup to recovery vault, DCR association
  - Uses `../modules/windows-server` module

### Key Vault (`sec_keyvault.tf`)
- `acme-health-dashbrd-key-vault` — Standard SKU, RBAC auth, network ACL deny-by-default
- CMK key: `acme-health-dashboard-cmk-key`, Disk Encryption Set: `acme-health-dashboard-hipaa-disk-encryption-set`

### Backup (`sec_backup_v2.tf`)
- Recovery vault with `acme_health_dashboard_v2` policy
- `bizinetazt01` enrolled

### Defender + Logging (`sec_defender.tf`, `sec_logging.tf`)
- Subscription Defender plans
- Local LAW, NSG diagnostics, activity log diagnostics

---

## Decommission Files

The following are legacy resources tracked for state only, **not active**, target destruction: **June 2026**.

| File | Contents |
|---|---|
| `decommission-ad.tf` | Legacy AD resources |
| `decommission-azurebackup.tf` | Old Azure Backup resources |
| `decommission-databaserebuild.tf` | Retired database rebuild VMs |
| `decommission-networking.tf` | Old Twingate connectors (super-woodlouse, copper-tarsier pre-migration) |
| `decommission-networkwatcherrg.tf` | NetworkWatcherRG resources |
| `decommission-rg-dashboard-*.tf` | Old resource groups (logs, misc, networking) |
| `decommission-snapshot-attck.tf` | Snapshot attack simulation artifacts |
| `decommission-vm-images.tf` | Old VM image artifacts |
| `imports-decommission.tf` | Import blocks for state adoption of decommission resources |

Do not modify, harden, or refactor decommission files — remove the file to destroy.

---

## How to Apply

```bash
cd dashboard/
terraform init
terraform plan
terraform apply
```

CI/CD: `.github/workflows/deploy-dashboard.yml` (Terraform 1.9.8).

**If the state is locked:**
```bash
az storage blob lease break \
  --blob-name dashboard.terraform.tfstate \
  --container-name terraform-state \
  --account-name acme-health-terraform-state \
  --auth-mode login \
  --subscription ce62d93b-2e73-46e0-a3d6-6a99156e9741
```

---
_Last pipeline verification: 2026-03-07 (run 2)_


<!-- smoke: 2026-03-09 -->

<!-- smoke: 2026-03-09 -->
