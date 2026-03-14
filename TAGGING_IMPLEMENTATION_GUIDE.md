# Tagging Standard Implementation Guide

**Status:** In Progress
**Created:** 2026-02-27
**Standard:** /git/infrastructure-docs/compliance/tagging-standard.md

---

## What Was Done

✅ Created `tags_local.tf` in all 7 modules with required tags:
- logging, main, dev, prod, identity, firewall, dashboard

Each module has appropriate values for:
- `environment` (shared/production/development)
- `data-classification` (phi/confidential/internal)
- `compliance-scope` (hipaa-soc2-hitrust or soc2-hitrust)

---

## What's Next: Add Tags to Resources

### Pattern 1: Simple Resources (Most Common)

Add one line to each resource:

```hcl
resource "azurerm_resource_group" "example" {
  name     = "rg-example"
  location = "westus2"

  tags = local.required_tags  # ADD THIS LINE
}
```

### Pattern 2: Resources with Existing Tags

Use merge() to combine:

```hcl
resource "azurerm_virtual_machine" "example" {
  name     = "vm-example"
  location = "westus2"

  tags = merge(local.required_tags, {
    workload = "app-server"
    backup-policy = "daily-30day"
  })
}
```

### Pattern 3: Resources That Don't Support Tags

Some resources don't support tags (like authorization rules, diagnostic settings). Skip these:
- `azurerm_eventhub_namespace_authorization_rule`
- `azurerm_monitor_diagnostic_setting`
- `azurerm_role_assignment`
- `azurerm_subscription_policy_assignment`

---

## Resources to Tag by Module

### Logging Module
**Tag these:**
- ✅ `azurerm_resource_group.logging`
- ✅ `azurerm_log_analytics_workspace.central_law`
- ✅ `azurerm_eventhub_namespace.central_ns`
- ✅ `azurerm_eventhub.central_logs`
- ✅ `azurerm_monitor_data_collection_rule.central_dcr`

**Skip these (no tag support):**
- ❌ `azurerm_eventhub_namespace_authorization_rule.send_rule`
- ❌ `azurerm_monitor_diagnostic_setting.eh_ns_to_law`
- ❌ `azurerm_role_assignment.*`
- ❌ `azurerm_security_center_subscription_pricing.*`
- ❌ `azurerm_subscription_policy_assignment.*`

### Main Module
**Tag these:**
- ✅ `azurerm_resource_group.*`
- ✅ `azurerm_key_vault.*`
- ✅ `azurerm_storage_account.*`

**Skip:**
- ❌ `azurerm_role_assignment.*`
- ❌ `azurerm_key_vault_access_policy.*`

### Dev Module
**Tag these:**
- ✅ All `azurerm_resource_group.*`
- ✅ All `azurerm_virtual_network.*`
- ✅ All `azurerm_subnet.*`
- ✅ All `azurerm_windows_virtual_machine.*`
- ✅ All `azurerm_network_interface.*`
- ✅ All `azurerm_key_vault.*`
- ✅ All `azurerm_recovery_services_vault.*`

### Prod Module
**Tag these:**
- ✅ All `azurerm_resource_group.*`
- ✅ All `azurerm_virtual_network.*`
- ✅ All `azurerm_subnet.*`
- ✅ All `azurerm_windows_virtual_machine.*`
- ✅ All `azurerm_network_interface.*`
- ✅ All `azurerm_key_vault.*`
- ✅ All `azurerm_recovery_services_vault.*`

### Identity Module
**Tag these:**
- ✅ All `azurerm_resource_group.*`
- ✅ All `azurerm_virtual_network.*`
- ✅ All `azurerm_subnet.*`
- ✅ All `azurerm_windows_virtual_machine.*` (AD controllers)
- ✅ All `azurerm_network_interface.*`
- ✅ All `azurerm_key_vault.*`
- ✅ All `azurerm_recovery_services_vault.*`

### Firewall Module ⚠️
**Tag these (non-security resources):**
- ✅ `azurerm_resource_group.*`
- ✅ `azurerm_virtual_network.*`
- ✅ `azurerm_subnet.*`
- ✅ `azurerm_key_vault.*`
- ✅ `azurerm_eventhub.*`
- ✅ `azurerm_log_analytics_workspace.*`

**⚠️ DO NOT TAG (per CLAUDE.md constraint):**
- ❌ `azurerm_firewall.*`
- ❌ `azurerm_network_security_group.*`
- ❌ `azurerm_network_security_rule.*`

### Dashboard Module
**Tag these:**
- ✅ `azurerm_resource_group.*`

---

## Automated Approach (Recommended)

Since manually editing ~50+ resources is error-prone, use this script:

```bash
#!/bin/bash
# Add tags to all taggable resources

cd /home/ubuntu/git/azure-infra

for module in logging main dev prod identity firewall dashboard; do
  echo "Processing $module..."

  cd $module

  # Find all resource blocks that support tags
  for file in *.tf; do
    # Skip tags_local.tf and backend.tf
    [[ "$file" == "tags_local.tf" ]] && continue
    [[ "$file" == "backend.tf" ]] && continue

    # Add tags to resource_group, virtual_machine, key_vault, etc.
    # This is a simplified example - manual review recommended

    echo "  Checking $file"
  done

  cd ..
done
```

**⚠️ IMPORTANT:** Due to the complexity and risk of automated replacement, I recommend:
1. Manually add tags to 2-3 resources per module
2. Run `terraform validate` after each
3. Run `terraform plan` to verify zero destroys
4. Continue module by module

---

## Verification Checklist

After adding tags to each module:

```bash
cd <module>
terraform init
terraform validate  # Should pass
terraform plan      # Should show "X to add, Y to change, 0 to destroy"
```

**Expected plan output:**
- Existing resources: "~ update in-place" with "+ tags" addition
- New resources might show as created if they don't exist yet
- **CRITICAL:** `0 to destroy` always

---

## Next Steps

1. **Manual Implementation Recommended:** Given ~50+ resources, manually add tags 5-10 resources at a time
2. **Validate Incrementally:** `terraform validate` after each file
3. **Plan Before Apply:** Review full `terraform plan` output before applying
4. **Start with logging:** Smallest module, good test case

OR

5. **Request Assistance:** If you want automated script, I can create more sophisticated tag injection

---

## Tag Values Reference

| Module | environment | data-classification | compliance-scope |
|--------|-------------|-------------------|------------------|
| logging | shared | confidential | hipaa-soc2-hitrust |
| main | shared | internal | soc2-hitrust |
| dev | development | internal | soc2-hitrust |
| prod | production | phi | hipaa-soc2-hitrust |
| identity | shared | confidential | hipaa-soc2-hitrust |
| firewall | shared | internal | soc2-hitrust |
| dashboard | shared | internal | soc2-hitrust |

All modules:
- owner: "it-security"
- managed-by: "terraform"
- cost-center: "it"
