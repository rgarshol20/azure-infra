# dev — Azure Development Subscription

Manages the AcmeHealth Group development environment: a MySQL/SQL application server and RDP gateway for non-production testing and validation.

**Subscription:** Dev (`11781e6f-5641-4d6c-8ebd-1f9c38a8770b`)
**Region:** West US (`westus`)
**Backend:** `acme-health-terraform-state` / container `terraform-state` / `dev.terraform.tfstate`

---

## What's Deployed

### Network (`net_vnet.tf`)
- Dev VNet with `servers` subnet
- Static IP allocation for the SQL server VM

### Virtual Machines

| VM | Size | Role | Data Disk |
|---|---|---|---|
| `bizsqlazt01` | Standard_E4s_v3 | MySQL/SQL application server | 500 GB Premium LRS |
| (RDP server) | (see svr_rdp.tf) | RDP gateway / jump host | — |

`bizsqlazt01` uses the `../modules/windows-server` module with:
- Custom image: `win2022_mysql_image` (data source)
- `encryption_at_host_enabled = true`, CMK disk encryption via `acme-health-dev-hipaa-disk-encryption-set`
- `AutomaticByOS` patching, AzurePolicyforWindows extension
- Backed up to recovery vault via `acme_health_dev_v2` policy
- DCR association to `windows-dcr`

### Key Vault (`sec_keyvault.tf`)
- `acme-health-dev-key-vault2` — Standard SKU, RBAC auth, network ACL deny-by-default
- CMK key: `acme-health-dev-cmk-key`, Disk Encryption Set: `acme-health-dev-hipaa-disk-encryption-set`

### Backup (`sec_backup_v2.tf`)
- Recovery vault with `acme_health_dev_v2` policy
- `bizsqlazt01` enrolled

### Defender + Logging (`sec_defender.tf`, `sec_logging.tf`)
- Subscription Defender plans
- Local LAW, NSG diagnostics, activity log diagnostics

---

## How to Apply

```bash
cd dev/
terraform init
terraform plan
terraform apply
```

CI/CD: `.github/workflows/deploy-dev.yml` (Terraform 1.9.8).

**If the state is locked:**
```bash
az storage blob lease break \
  --blob-name dev.terraform.tfstate \
  --container-name terraform-state \
  --account-name acme-health-terraform-state \
  --auth-mode login \
  --subscription ce62d93b-2e73-46e0-a3d6-6a99156e9741
```

---

## Notes

- Dev mirrors the production security posture (CMK, host encryption, backup) but uses smaller VM sizes
- The `svr_rdp.tf` RDP server is a jump host — review access rules before exposing externally

---
_Last pipeline verification: 2026-03-07 (run 2)_


<!-- smoke: 2026-03-09 -->

<!-- smoke: 2026-03-09 -->
