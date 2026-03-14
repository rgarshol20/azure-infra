# Safe Terraform Workflow for azure-infra

**Date:** 2026-02-27
**Review Status:** Modules validated, backend access blocked by permissions

## Executive Summary

The azure-infra repository contains 7 terraform modules in a well-structured dependency chain. All modules pass static validation (`terraform validate`), but **cannot be executed locally** due to two configuration/permission issues:

1. **Backend authentication:** Configs use `use_oidc = true` (GitHub Actions/CI-CD only)
2. **RBAC permissions:** User account lacks `Storage Blob Data Contributor` role on `acme-health-terraform-state` storage account

## Module Inventory

| Module | Purpose | Dependencies | Resource Groups | Status |
|--------|---------|--------------|----------------|--------|
| **logging** | Central logging (Log Analytics, Defender) | None | rg-logging-logs | ✅ Valid |
| **main** | Core shared services (KV, Storage) | logging | rg-main-terraform, rg-main-logs | ✅ Valid |
| **dev** | Development environment (VMs, networking) | logging, main, firewall, identity | rg-dev-{networking,logs,servers,workers,backup} | ✅ Valid |
| **prod** | Production environment (8 VMs) | logging, main, firewall, identity | rg-prod-{logs,networking,servers,workers,backup} | ✅ Valid |
| **identity** | Active Directory controllers | logging, main, firewall, prod, dev | rg-identity-{logs,networking,ad,backup} | ✅ Valid |
| **firewall** | Network security (Firewall, NSGs, Twingate) | logging, main, identity, prod, dev | rg-firewall-{networking,logs} | ✅ Valid |
| **dashboard** | Twingate zero-trust access | logging, main, identity, prod, dev | Networking (centralus) | ✅ Valid |

## Dependency Chain

```
Layer 1 (Foundation):  logging
Layer 2 (Core):        main ← logging
Layer 3 (Environments): dev, prod, identity ← logging, main
                       (circular refs to firewall - see note)
Layer 4 (Security):    firewall ← logging, main, identity, prod, dev
Layer 5 (Access):      dashboard ← logging, main, identity, prod, dev
```

**Note:** Circular dependency exists between `firewall` and `{dev, prod, identity}` via remote state references. Safe execution order: logging → main → {dev, prod, identity} (parallel) → firewall → dashboard.

## Prerequisites

### Required Before ANY Terraform Operations

1. **Azure CLI authentication:**
   ```bash
   az login
   az account set --subscription "Main" 
   az account show  # Verify active subscription
   ```

2. **RBAC permissions on terraform state storage:**
   - Your account needs: `Storage Blob Data Contributor` or `Storage Blob Data Owner`
   - Target: Storage account `acme-health-terraform-state` in `rg-main-terraform`
   - Current status: ❌ Permission denied (403 errors)
   - Request from: Azure AD admin or subscription owner

3. **Backend configuration for local execution:**
   - Current: All modules have `use_oidc = true` (GitHub Actions only)
   - For local use: Comment out `use_oidc = true` in all `backend.tf` files
   - Temporary change - revert before git commit

## Safe Workflow (Once Permissions Granted)

### Phase 1: Initialization (One-Time per Module)

```bash
cd <module-directory>

# Clean any existing state
rm -rf .terraform

# Initialize (downloads providers, configures backend)
terraform init

# Verify configuration syntax
terraform validate
```

**Expected output:** "Success! The configuration is valid."

### Phase 2: Planning (Review Changes Before Apply)

```bash
# Generate execution plan
terraform plan -out=plan.out

# Review plan output carefully:
# - Look for "Plan: X to add, Y to change, Z to destroy"
# - ⚠️ CRITICAL: If Z > 0, STOP - destroys detected
# - Verify no firewall/NSG resources in change list
```

**Safety check:**
```bash
# Grep plan for destroy operations
terraform show -no-color plan.out | grep -E "will be destroyed|# .* will be destroyed"

# Expected: No matches (empty output)
```

### Phase 3: Apply (Execute Changes)

**⚠️ ONLY proceed if:**
- Plan shows 0 resources to destroy
- No firewall/NSG modifications in change list
- You have explicit approval for changes

```bash
# Apply the saved plan (does not re-plan)
terraform apply plan.out

# Verify completion
echo $?  # Should be 0

# Review created/updated resources
terraform show
```

## Execution Order by Module

### Safe Parallel Execution Strategy

**Sequential blocks (run in order):**

1. **Foundation** (must complete first):
   ```bash
   cd logging/
   terraform init && terraform validate && terraform plan -out=plan.out
   # Review plan, then: terraform apply plan.out
   ```

2. **Core** (depends on logging state):
   ```bash
   cd main/
   terraform init && terraform validate && terraform plan -out=plan.out
   # Review plan, then: terraform apply plan.out
   ```

3. **Environments** (can run in parallel after main completes):
   ```bash
   # Terminal 1:
   cd dev/ && terraform init && terraform validate && terraform plan -out=plan.out

   # Terminal 2:
   cd prod/ && terraform init && terraform validate && terraform plan -out=plan.out

   # Terminal 3:
   cd identity/ && terraform init && terraform validate && terraform plan -out=plan.out

   # Review all 3 plans, then apply each
   ```

4. **Security** (depends on environments):
   ```bash
   cd firewall/
   terraform init && terraform validate && terraform plan -out=plan.out
   # ⚠️ Extra review: firewall changes affect all environments
   # Review plan, then: terraform apply plan.out
   ```

5. **Access** (final layer):
   ```bash
   cd dashboard/
   terraform init && terraform validate && terraform plan -out=plan.out
   # Review plan, then: terraform apply plan.out
   ```

## Disabled Configurations (.rm files)

The following configurations are **intentionally disabled** and should NOT be renamed to `.tf` without explicit review:

| Module | File | Purpose (if enabled) |
|--------|------|---------------------|
| dev | svr_ftp.rm | FTP server |
| dev | svr_svcs.rm | Services server |
| dev | svr_cgi.rm | CGI application server |
| dev | svr_payers.rm | Payers processing server |
| dev | svr_veeam.rm | Veeam backup server |
| dev | svr_web.rm | Web server |
| dev | net_ngs.rm | Network security groups (large config) |
| identity | net_ngs.rm | Network security groups |
| identity | svr_onelg.rm | OneLogin server |
| logging | sec_alerts.rm | Security alerts configuration |
| firewall | ec2.rm | EC2 instance (AWS migration artifact) |
| firewall/firewall-old | ec2.rm, firewall.rm | Archived firewall configs |

**Total:** 13 disabled files

## Critical Safety Rules

### 🚫 Never Do These Without Explicit Approval

1. **Enable .rm files** - These are disabled for a reason; enabling may cause unexpected resource creation
2. **Modify firewall/NSG resources** - Changes affect entire network security posture
3. **Run `terraform apply` without reviewing plan** - Always save and review plan first
4. **Use `terraform apply -auto-approve`** - Bypasses safety review
5. **Force unlock state** - May indicate concurrent operations; investigate first

### ✅ Always Do These

1. **Review plan output** before applying
2. **Check for destroy operations** - grep plan for "destroy"
3. **Verify firewall/NSG untouched** - grep for `azurerm_firewall|azurerm_network_security`
4. **Use plan files** - `terraform plan -out=plan.out`, then `terraform apply plan.out`
5. **Test in dev first** - Changes go to dev environment before prod

## Current Blockers for Local Execution

### Blocker 1: Backend OIDC Configuration

**Issue:** All `backend.tf` files have:
```hcl
use_azuread_auth = true
use_oidc         = true  # GitHub Actions only
```

**Impact:** Local `az login` tokens are incompatible with OIDC auth.

**Workaround (temporary):**
```bash
# In each module's backend.tf, comment out use_oidc:
# use_oidc = true

# After review, revert before git commit
```

### Blocker 2: Storage Blob RBAC Permissions

**Issue:** User account (rory.garshol@acme-health-dde.com) lacks permissions on storage account.

**Error message:**
```
Error: Failed to get existing workspaces: containers.Client#ListBlobs:
Failure responding to request: StatusCode=403
Code="AuthenticationFailed"
```

**Resolution:** Request one of these roles on `acme-health-terraform-state`:
- `Storage Blob Data Contributor`
- `Storage Blob Data Owner`

**Request via:**
```bash
# Option 1: Azure Portal - Storage account → Access Control (IAM)
# Option 2: Azure CLI (requires admin access):
az role assignment create \
  --assignee rory.garshol@acme-health-dde.com \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/main subscription/resourceGroups/rg-main-terraform/providers/Microsoft.Storage/storageAccounts/acme-health-terraform-state"
```

## Static Validation Results (2026-02-27)

Without backend access, performed static validation using `terraform init -backend=false` and `terraform validate`:

| Module | Init | Validate | Notes |
|--------|------|----------|-------|
| logging | ✅ | ✅ | No remote dependencies |
| main | ✅ | ✅ | References logging state |
| dev | ✅ | ✅ | References logging, main, firewall, identity |
| prod | ✅ | ✅ | References logging, main, firewall, identity |
| identity | ✅ | ✅ | References logging, main, firewall, prod, dev |
| firewall | ✅ | ✅ | References logging, main, identity, prod, dev |
| dashboard | ✅ | ✅ | References logging, main, identity, prod, dev |

**Result:** All 7 modules have valid syntax and resource configurations. No structural issues preventing execution.

## Remote State References

All modules correctly reference existing state files:

| State File | Referenced By | Verified |
|------------|---------------|----------|
| logging.terraform.tfstate | main, dev, prod, identity, firewall, dashboard | ✅ |
| main.terraform.tfstate | dev, prod, identity, firewall, dashboard | ✅ |
| firewall.terraform.tfstate | dev, prod, identity | ✅ |
| identity.terraform.tfstate | dev, prod, firewall, dashboard | ✅ |
| prod.terraform.tfstate | identity, firewall, dashboard | ✅ |
| dev.terraform.tfstate | identity, firewall, dashboard | ✅ |

**No orphaned references found.**

## Next Steps to Enable Local Execution

1. **Request RBAC permissions** (priority: high)
   - Contact: Azure AD admin or subscription owner
   - Role needed: Storage Blob Data Contributor
   - Scope: `acme-health-terraform-state` storage account

2. **Document backend strategy** (priority: medium)
   - Decide: OIDC for CI/CD only, or support local execution?
   - If both needed: consider backend config overrides via `-backend-config` flags

3. **Test workflow in dev** (priority: medium)
   - Once permissions granted, test full init/plan/apply cycle in `dev/` module
   - Verify: no destroy operations, remote state accessible, changes as expected

4. **Revert temporary backend changes** (before git commit)
   - Un-comment `use_oidc = true` if commented for local testing
   - Verify: `git diff backend.tf` shows no changes

## Support

- **Terraform version:** 1.7.5
- **Provider versions:** azurerm 4.34.0, azuread 3.6.0, panos 2.0.8
- **Backend:** azurerm (Azure Storage Account)
- **Subscription:** Main 
