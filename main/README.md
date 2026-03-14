# main — Azure Management Subscription

Manages enterprise governance, Entra ID, Terraform state storage, Defender for Cloud, and subscription-level security controls for the AcmeHealth Group Azure tenant.

**Subscription:** Main 
**Region:** West US (`westus`)
**Backend:** `acme-health-terraform-state` / container `terraform-state` / `main.terraform.tfstate`

---

## What's Deployed

### Entra ID / Identity
- **Break glass accounts** — `break-glass-1` and `break-glass-2` (Global Admin, cloud-only, excluded from all Conditional Access policies)
- **CA exclusion group** — `CA-Exclusion-BreakGlass`
- **Conditional access policies** — `conditional-access.tf`; four hardcoded legacy-auth exemption UUIDs pending identity review (see inline TODO comments)
- **Maester graph permissions** — delegated API permissions for compliance testing (`maester-graph-permissions.tf`)
- **IAM** — subscription-level RBAC assignments (`iam.tf`)

### Key Vault
- `acme-health-main-key-vault` — Standard SKU, RBAC auth, network ACL deny-by-default, CMK key + Disk Encryption Set (`acme-health-main-hipaa-disk-encryption-set`)

### Terraform State Storage
- `acme-health-terraform-state` — CMK encrypted, SAS disabled (`shared_access_key_enabled = false`), RBAC-only, network open for CI/CD runners (justified in code)
- Containers: `terraform-state`, `installfiles`, `configfiles`

### Defender for Cloud (`sec_defender.tf`)
- **CloudPosture** — Standard (agentless VM scanning, K8s discovery, container VA, Entra permissions, sensitive data discovery)
- **StorageAccounts** — DefenderForStorageV2 with `OnUploadMalwareScan` + `SensitiveDataDiscovery` (~$0.15/GB scan cost on uploads)
- **Arm** — Standard / PerSubscription
- **HIPAA HITRUST** — policy set assigned at subscription scope with remediation identity
- **Security contact** — `roryg@acme-health.com`, high-severity + admin notifications enabled

### Activity Log Alerts (`sec_activity_alerts.tf`)
Ten CIS Azure 5.1.x alerts routing to `ag-security-ops-alerts` action group (`roryg@acme-health.com`):

| Alert | Operation |
|---|---|
| NSG create/update | `Microsoft.Network/networkSecurityGroups/write` |
| NSG delete | `Microsoft.Network/networkSecurityGroups/delete` |
| NSG rule create/update | `Microsoft.Network/networkSecurityGroups/securityRules/write` |
| NSG rule delete | `Microsoft.Network/networkSecurityGroups/securityRules/delete` |
| Security solution create/update | `Microsoft.Security/securitySolutions/write` |
| Security solution delete | `Microsoft.Security/securitySolutions/delete` |
| SQL firewall rule create/update | `Microsoft.Sql/servers/firewallRules/write` |
| SQL firewall rule delete | `Microsoft.Sql/servers/firewallRules/delete` |
| Policy assignment create/update | `Microsoft.Authorization/policyAssignments/write` |
| Policy assignment delete | `Microsoft.Authorization/policyAssignments/delete` |

### Logging
- Local Log Analytics workspace for Main subscription diagnostics
- Activity log diagnostic settings routed to LAW + archive storage
- Break glass sign-in scheduled query alert (fires within 5 min of any break glass authentication)

---

## How to Apply

```bash
cd main/
terraform init
terraform plan
terraform apply
```

CI/CD: `.github/workflows/deploy-main.yml` (Terraform 1.9.8, OIDC auth).

**If the state is locked** from a cancelled CI run:
```bash
az storage blob lease break \
  --blob-name main.terraform.tfstate \
  --container-name terraform-state \
  --account-name acme-health-terraform-state \
  --auth-mode login \
  --subscription <subscription id>
```

---

## Recent Changes (2026-03)

- Added `azurerm_security_center_contact` — fixes 3 Defender for Cloud recommendations
- Added 10 CIS 5.1.x activity log alerts (`sec_activity_alerts.tf`)
- Added `OnUploadMalwareScan` extension to Defender for Storage (fixes 1 Defender recommendation)
- Annotated four legacy-auth CA exemption UUIDs with TODO comments

---

## Known Issues / Notes

- `CloudPosture` shows `Free` in live Azure despite `Standard` in Terraform — a prior apply did not complete; re-run `terraform apply` to sync the Defender CSPM plan
- The four hardcoded UUIDs in `conditional-access.tf` `block_legacy_auth.excluded_users` need identity review

---
_Last pipeline verification: 2026-03-07 (run 2)_


<!-- smoke: 2026-03-09 -->

<!-- smoke: 2026-03-09 -->
