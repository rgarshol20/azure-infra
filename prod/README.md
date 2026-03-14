# prod — Azure Production Subscription

Manages the primary production workloads for AcmeHealth Group: Windows Server VMs, Active Directory, file services, and supporting infrastructure.

**Subscription:** Prod 
**Region:** West US (`westus`)
**Backend:** `acme-health-terraform-state` / container `terraform-state` / `prod.terraform.tfstate`

---

## What's Deployed

### Network (`net_vnet.tf`)
- Production VNet with subnets: `servers`, `dmz`
- NSGs on each subnet with diagnostic settings → LAW + archive
- Workers NSG tagged with `local.required_tags` (applied 2026-03)

### Virtual Machines

All VMs use the `../modules/windows-server` module with:
- `encryption_at_host_enabled = true`
- CMK disk encryption via `acme-health-prod-hipaa-disk-encryption-set`
- `AutomaticByPlatform` patch assessment
- AzurePolicyforWindows GuestConfiguration extension
- Daily backup to `rsv-core-prod` via `acme_health_prod` policy
- DCR association to `windows-dcr` for log forwarding

| VM | Size | Role | Data Disk |
|---|---|---|---|
| `BIZADSAZP01` | Standard_E32s_v3 | Business AD / apps | 2 TB Premium LRS |
| `BIZARCAZP01` | (see svr_bizarc.tf) | Business archive | — |
| `BIZFTPAZP01` | (see svr_bizftp.tf) | FTP server | — |
| `BIZWRKAZP0x` | (see svr_bizwrk.tf) | Business workstation (multi-instance) | — |
| `CGIADSAZP01` | (see svr_cgiads.tf) | CGI AD / compliance | 2 disks |
| `CGIRDPAZP01` | (see svr_cgirdp.tf) | CGI RDP gateway | — |
| `NNTFIMAZP01` | (see svr_nnt.tf) | NNT FIM server | — |
| `VEEAMAZP01` | (see svr_veeam.tf) | Veeam backup server | — |

### Key Vault (`sec_keyvault.tf`)
- `prod-dde-key-vault` — Standard SKU, RBAC auth, network ACL deny-by-default
- CMK key: `acme-health-prod-cmk-key` (2048-bit RSA, 2-year rotation)
- Disk Encryption Set: `acme-health-prod-hipaa-disk-encryption-set`
- Admin password secret with 2028-03-05 expiration

### Backup (`sec_backup.tf`)
- Recovery vault: `rsv-core-prod` (or as named in module)
- Policy: `AcmeHealthProd` (Daily 02:00 UTC, 30-day daily, 12-week weekly, 12-month monthly)
- All production VMs enrolled

### Defender (`sec_defender.tf`)
- Subscription-scoped Defender plans (VM, SQL, etc.)
- HIPAA policy assignment

### Logging (`sec_logging.tf`)
- Local LAW for Prod subscription
- NSG diagnostic settings → LAW + archive
- Activity log diagnostic settings → LAW + EventHub + archive
- Windows DCR for VM log collection

---

## How to Apply

```bash
cd prod/
terraform init
terraform plan
terraform apply
```

CI/CD: `.github/workflows/deploy-prod.yml` (Terraform 1.9.8).

**If the state is locked:**
```bash
az storage blob lease break \
  --blob-name prod.terraform.tfstate \
  --container-name terraform-state \
  --account-name acme-health-terraform-state \
  --auth-mode login \
  --subscription <subscription id>
```

---

## Recent Changes (2026-03)

- Added `tags = local.required_tags` to `nsg_workers` (was missing)
- Removed commented-out dead route block `default-to-prod`
- Moved activity log diagnostic settings to `diagnostic-settings` module (removed standalone EventHub auth rule)
- All VMs migrated to `windows-server` module with `moved` blocks (zero-downtime state refactor)

---
_Last pipeline verification: 2026-03-07 (run 2)_


<!-- smoke: 2026-03-09 -->

<!-- smoke: 2026-03-09 -->
