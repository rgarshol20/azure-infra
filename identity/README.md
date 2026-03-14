# identity — Azure Identity Subscription

Manages Active Directory domain controllers and identity infrastructure for the AcmeHealth Group on-premises/hybrid identity model.

**Subscription:** Identity 
**Region:** West US (`westus`)
**Backend:** `acme-health-terraform-state` / container `terraform-state` / `identity.terraform.tfstate`

---

## What's Deployed

### Network (`net_vnet.tf`)
- Identity VNet with subnets sized for AD controllers
- NSG rules appropriate for AD traffic (DNS, Kerberos, LDAP, RPC)

### Active Directory Domain Controllers

| VM | Size | Role |
|---|---|---|
| `ACTDIRAZP01` | Standard_B2ms | Primary domain controller |
| `ACTDIRAZP02` | Standard_B2ms | Secondary domain controller |

Both VMs:
- CMK disk encryption via `acme-health-id-hipaa-disk-encryption-set`
- Host encryption and AzurePolicy extension
- Backed up via recovery vault

### Key Vault (`sec_keyvault.tf`)
- `acme-health-id-key-vault` — Standard SKU, RBAC auth, network ACL deny-by-default
- CMK key: `acme-health-id-cmk-key`, Disk Encryption Set: `acme-health-id-hipaa-disk-encryption-set`

### Backup (`sec_backup.tf`)
- Recovery vault with daily backup policy for both AD controllers

### IAM (`iam.tf`)
- Cross-subscription role assignments for identity-related operations

### Defender + Logging (`sec_defender.tf`, `sec_logging.tf`)
- Subscription Defender plans
- Local LAW, NSG diagnostics, activity log diagnostics

---

## How to Apply

```bash
cd identity/
terraform init
terraform plan
terraform apply
```

CI/CD: `.github/workflows/deploy-identity.yml` (Terraform 1.9.8).

**If the state is locked:**
```bash
az storage blob lease break \
  --blob-name identity.terraform.tfstate \
  --container-name terraform-state \
  --account-name acme-health-terraform-state \
  --auth-mode login \
  --subscription <subscription id>
```

---

## Notes

- DC VMs use `Standard_B2ms` — upgrade if AD replication latency is observed under load
- Both controllers should be in separate availability zones if AZs become available in West US
- AD FSMO roles are not tracked in Terraform — document separately

---
_Last pipeline verification: 2026-03-07 (run 2)_


<!-- smoke: 2026-03-09 -->

<!-- smoke: 2026-03-09 -->
