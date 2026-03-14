# =============================
# Tenant Root Management Group — Regulatory Compliance
# =============================
# Assigning HIPAA/HITRUST at the tenant root management group causes
# Defender for Cloud to surface it in the Regulatory Compliance dashboard
# at the tenant scope, not just per-subscription.
# The tenant root MG name is always equal to the tenant ID in Azure.

data "azurerm_policy_set_definition" "hipaa_hitrust_mg" {
  name = var.hitrust_assessment_name
}

data "azurerm_policy_set_definition" "iso27001_mg" {
  display_name = "ISO 27001:2013"
}

data "azurerm_policy_set_definition" "soc2_mg" {
  name = "4054785f-702b-4a98-9215-009cbd58b141"
}

data "azurerm_policy_set_definition" "cis_mg" {
  name = "06f19060-9e68-4070-92ca-f15cc126059e"
}

# The tenant root management group ID is deterministic — no data source needed.
# Avoids requiring the deploy SP to have Management Group Reader at tenant root.
locals {
  tenant_root_mg_id = "/providers/Microsoft.Management/managementGroups/${var.tenant_id}"
}

resource "azurerm_management_group_policy_assignment" "hipaa_hitrust" {
  name                 = "hipaa-hitrust"
  display_name         = "HIPAA HITRUST 9.2"
  policy_definition_id = data.azurerm_policy_set_definition.hipaa_hitrust_mg.id
  management_group_id  = local.tenant_root_mg_id
  location             = "westus2"

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_management_group_policy_assignment" "iso27001" {
  name                 = "iso27001-2013"
  display_name         = "ISO 27001:2013"
  policy_definition_id = data.azurerm_policy_set_definition.iso27001_mg.id
  management_group_id  = local.tenant_root_mg_id
  location             = "westus2"

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_management_group_policy_assignment" "soc2" {
  name                 = "soc2"
  display_name         = "SOC 2"
  policy_definition_id = data.azurerm_policy_set_definition.soc2_mg.id
  management_group_id  = local.tenant_root_mg_id
  location             = "westus2"

  # SOC 2 v1.12.0 requires these Kubernetes-related parameters.
  # Using permissive defaults — adjust if AKS clusters have stricter requirements.
  parameters = jsonencode({
    "allowedContainerImagesRegex-febd0533-8e55-448f-b837-bd0e06f16469" = { value = ".*" }
    "cpuLimit-e345eecc-fa47-480f-9e88-67dcc122b164"                    = { value = "200m" }
    "memoryLimit-e345eecc-fa47-480f-9e88-67dcc122b164"                 = { value = "1Gi" }
  })

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_management_group_policy_assignment" "cis_azure" {
  name                 = "cis-azure"
  display_name         = "CIS Azure Foundations Benchmark"
  policy_definition_id = data.azurerm_policy_set_definition.cis_mg.id
  management_group_id  = local.tenant_root_mg_id
  location             = "westus2"

  identity {
    type = "SystemAssigned"
  }
}
