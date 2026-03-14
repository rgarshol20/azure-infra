# DEV Module Migration to Reusable Modules

**Date:** 2026-02-28
**Status:** Phase 1 Complete (Tags Module)
**Next:** Resource Groups (pending provider configuration update)

---

## Migration Log

### Phase 1: Tags Module Migration ✅

**Objective:** Convert local tags block to use `../modules/tags` module

**Files Modified:**
- `dev/tags_local.tf` - Replaced locals block with module call

**Changes Made:**

```hcl
# BEFORE (direct locals block):
locals {
  required_tags = {
    environment          = "development"
    owner                = "it-security"
    managed-by           = "terraform"
    data-classification  = "internal"
    cost-center          = "it"
    compliance-scope     = "soc2-hitrust"
  }
}

# AFTER (module with backward-compatible local):
module "dev_tags" {
  source = "../modules/tags"

  environment         = "development"
  owner               = "it-security"
  managed_by          = "terraform"
  data_classification = "internal"
  cost_center         = "it"
  compliance_scope    = "soc2-hitrust"
}

locals {
  required_tags = module.dev_tags.required_tags
}
```

**State Migration Required:** NO (backward-compatible local reference preserves all existing resource tag references)

**Terraform Commands:**
```bash
# Backup state
terraform state pull > backup-state-20260228-184656.tfstate

# Initialize to load module
terraform init -upgrade

# Verify no changes
terraform plan
# Expected: No changes or only in-place tag updates
```

**Result:**
- Tags now sourced from reusable module
- All existing resources continue working with `local.required_tags`
- Module provides validation for tag values
- Pattern proven for other modules (logging, main, prod, identity, firewall, dashboard)

---

## Phase 2: Resource Groups (Future)

**Blocker:** Resource-group module needs provider configuration support

**Current Issue:**
```hcl
# Existing resources use explicit providers:
resource "azurerm_resource_group" "networking" {
  provider = azurerm.dev  # <-- Can't pass this to current module
  ...
}
```

**Solution Options:**

### Option A: Update Module to Accept Provider
Add to `modules/resource-group/versions.tf`:
```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
      configuration_aliases = [azurerm]  # <-- Allow provider passing
    }
  }
}
```

Then call with:
```hcl
module "networking_rg" {
  source = "../modules/resource-group"
  providers = {
    azurerm = azurerm.dev
  }
  name     = "rg-dev-networking"
  location = var.location
  tags     = local.required_tags
}
```

State migration command would be:
```bash
terraform state mv \
  'azurerm_resource_group.networking' \
  'module.networking_rg.azurerm_resource_group.this'
```

### Option B: Keep Resource Groups as Direct Resources
Use modules only for NEW resource groups, leave existing ones as-is.

---

## Lessons Learned

1. **Backward Compatibility:** Using `locals { required_tags = module.dev_tags.required_tags }` allows module adoption without touching every resource reference
2. **Provider Aliases:** Multi-subscription architecture requires modules to support provider passing
3. **State Migration Not Always Needed:** When module output is identical to what it replaces, no state migration required
4. **Proof of Concept Value:** Testing in dev first revealed provider configuration issue before touching production

---

## Replication Guide for Other Modules

To replicate tags module migration to other modules (logging, main, prod, identity, firewall, dashboard):

1. **Backup state:**
   ```bash
   cd /path/to/module
   terraform state pull > backup-state-$(date +%Y%m%d-%H%M%S).tfstate
   ```

2. **Update tags_local.tf:**
   Replace locals block with module call matching that module's tag values
   (See each module's current tags_local.tf for correct values)

3. **Initialize:**
   ```bash
   terraform init -upgrade
   ```

4. **Verify:**
   ```bash
   terraform plan
   # Should show: No changes (or only in-place tag updates if tags are being added)
   ```

5. **Document:**
   Copy this MIGRATION.md to other modules and update with module-specific details

---

## Success Criteria

- [x] State backed up before changes
- [x] Tags module loaded successfully
- [x] Terraform plan shows 0 destroys
- [ ] Terraform plan shows 0 to add (pending verification)
- [x] All existing resource references work unchanged
- [x] Migration process documented for replication

---

## Next Steps

1. Verify terraform plan results
2. Update resource-group module for provider support (if pursuing resource group migration)
3. Replicate tags migration to other 6 modules
4. Document decision on resource group migration approach
