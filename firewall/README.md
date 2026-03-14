# firewall — Azure Firewall Subscription

Manages the AcmeHealth Group network security perimeter: Palo Alto VM-Series firewall, Panorama, syslog collection, Arctic Wolf threat detection, Twingate zero-trust access, and all associated networking.

**Subscription:** Firewall 
**Region:** West US (`westus`)
**Backend:** `acme-health-terraform-state` / container `terraform-state` / `firewall.terraform.tfstate`

---

## What's Deployed

### Network (`net_vnet.tf`, `net_nsg.tf`)
- **VNet:** `vnet-firewall` (10.99.0.0/16)
- **Subnets:** public, private (10.99.2.x), mgmt (10.99.0.x), dmz, ad, twingate
- **NSGs:** public (pass-through — Palo Alto enforces perimeter policy), private, mgmt, dmz, ad, twingate
- **VNet flow logs:** `flowlog-vnet-firewall` → archive storage + traffic analytics (Log Analytics)
- **Network Watcher:** `NetworkWatcher_westus`

### Palo Alto Firewall (`net_firewall.tf`)
- **VM:** `ACME-HEALTH-SVCS-FW` — three NICs (mgmt, public, private)
- **Management PIP:** `pip-acme-health-svcsvnet-westus-mgmt2`
- **Public PIP:** `AcmeHealthSvcsPublicIP`
- OS disk: CMK encrypted via DES from `acme-health-fw-keyvault`

### Panorama (`net_panorama.tf`)
- **VM:** `ACME-HEALTH-SVCS-PANORAMA` — Palo Alto BYOL marketplace image (v12.1.2)
- **Management PIP:** `panorama-pip` (Static, Standard SKU)
- Password auth — SSH keys not supported by appliance; disk encrypted via DES
- Note: host encryption not supported by Palo Alto marketplace image

### Syslog Collector (`net_rsyslog.tf`)
- **VM:** `syslog-vm` — Ubuntu 22.04 LTS (Standard_B1ms), private IP 10.99.2.5
- Receives syslog from Palo Alto on UDP/TCP 514
- Azure Monitor Agent (AMA) extension → `syslog-dcr` Data Collection Rule → central LAW
- Backed up by `rsv-core-firewall`

### Arctic Wolf VLC (`net_awnvlc.tf`)
- **VM:** `arcticwolfvlc` — Arctic Wolf Virtual Log Collector (Standard_D2as_v5), private IP 10.99.2.11
- Marketplace image: `arcticwolfnetworks1680048607525/awn-virtual-appliance`
- Host encryption enabled; disk encrypted via DES
- Backed up by `rsv-core-firewall`

### Twingate Zero-Trust (`net_twingate.tf`)
- Two container group connectors: `twingate-connector-prophetic-magpie`, `twingate-connector-outstanding-hampster`
- IP type: Private; deployed into `twingate` subnet
- Tokens managed via Terraform variables (not in state)

### Key Vault (`sec_keyvault.tf`)
- `acme-health-fw-keyvault` — Standard SKU, RBAC auth, network ACL deny-by-default, CMK key + Disk Encryption Set (`acme-health-firewall-hipaa-disk-encryption-set`)

### Backup (`sec_backup.tf`)
- Recovery vault: `rsv-core-firewall` (soft delete, Unlocked immutability)
- Policy: `acme_health_firewall` (daily 02:00 UTC, 30-day daily, 12-week weekly, 12-month monthly)
- Protected VMs: `syslog-vm`, `arcticwolfvlc`
- Palo Alto and Panorama VMs are excluded — not compatible with Azure Backup; use PAN-OS config export

### Logging (`sec_logging.tf`)
- Local LAW: `acme-health-firewall-law` (30-day retention)
- Data Collection Endpoint: `dce-firewall`
- DCR `windows-dcr` — Windows Event Log → LAW + archive storage
- DCR `syslog-dcr` — Syslog (auth, daemon, kern, local0–local7, etc.) → LAW + archive storage
- NSG diagnostic settings for all 6 NSGs (NetworkSecurityGroupEvent + RuleCounter)
- Key Vault diagnostic settings (AuditEvent + AllMetrics) → LAW + EventHub

### EventHub (`sec_eventhub.tf`)
- Authorization rule for sending logs to the central EventHub in the logging subscription

---

## Decommission Files

Many `decommission-*.tf` files track legacy resources for state management only. These resources are **not active** and will be destroyed by **June 2026**. Do not modify, harden, or refactor them — remove the file to destroy.

Current decommission inventory:
- `decommission-ad_*.tf` — legacy AD resources
- `decommission-azurebackuprg_*.tf` — old AzureBackupRG resources (EventGrid system topic removed)
- `decommission-databaseultra_*.tf` — retired database VMs (3 files)
- `decommission-desktopsrebuild_*.tf` — retired desktop VMs (3 files)
- `decommission-ftpserver_*.tf` — retired FTP servers (2 files)
- `decommission-networking-*.tf` — retired networking resources
- `decommission-vm_images_*.tf` — old image artifacts
- `imports-decommission.tf` — import blocks for state adoption (stale blocks removed as resources are destroyed)

---

## How to Apply

```bash
cd firewall/
terraform init
terraform plan
terraform apply
```

CI/CD: `.github/workflows/deploy-firewall.yml` (Terraform 1.9.8).

**If the state is locked:**
```bash
az storage blob lease break \
  --blob-name firewall.terraform.tfstate \
  --container-name terraform-state \
  --account-name acme-health-terraform-state \
  --auth-mode login \
  --subscription <subscription id>
```

---

## Recent Changes (2026-03)

- Removed stale EventGrid system topic import block and resource definition (auto-managed by Azure Backup; not Terraform-provisionable)
- Added LOCAL0–LOCAL7 facilities to syslog DCR (captures Palo Alto syslog via local facilities)
- Replaced contradictory `public_nsg` rules with honest pass-through + checkov skips
- Removed commented-out dead route block from `net_vnet.tf`
- Reverted `policy_type = "V2"` on backup policy — `BMSUserErrorPolicyObjectInUse` blocks recreation while VMs are protected

---
_Last pipeline verification: 2026-03-07 (run 2)_


<!-- smoke: 2026-03-09 -->

<!-- smoke: 2026-03-09 -->
