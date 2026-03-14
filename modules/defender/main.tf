# Defender for Servers Pricing
resource "azurerm_security_center_subscription_pricing" "servers" {
  count         = var.enable_defender_for_servers ? 1 : 0
  tier          = var.defender_servers_tier
  resource_type = "VirtualMachines"
  subplan       = var.defender_servers_subplan

  lifecycle {
    ignore_changes = [extension]
  }
}

# Defender CSPM Pricing with Extensions
resource "azurerm_security_center_subscription_pricing" "cspm" {
  count         = var.enable_defender_cspm ? 1 : 0
  tier          = "Standard"
  resource_type = "CloudPosture"

  # AgentlessVmScanning extension
  dynamic "extension" {
    for_each = var.cspm_agentless_vm_scanning_enabled ? [1] : []
    content {
      name = "AgentlessVmScanning"
      additional_extension_properties = {
        ExclusionTags = jsonencode([])
      }
    }
  }

  # AgentlessDiscoveryForKubernetes extension
  dynamic "extension" {
    for_each = var.cspm_agentless_k8s_enabled ? [1] : []
    content {
      name                            = "AgentlessDiscoveryForKubernetes"
      additional_extension_properties = {}
    }
  }

  # ContainerRegistriesVulnerabilityAssessments extension
  dynamic "extension" {
    for_each = var.cspm_container_va_enabled ? [1] : []
    content {
      name                            = "ContainerRegistriesVulnerabilityAssessments"
      additional_extension_properties = {}
    }
  }

  # EntraPermissionsManagement extension
  dynamic "extension" {
    for_each = var.cspm_entra_permissions_enabled ? [1] : []
    content {
      name                            = "EntraPermissionsManagement"
      additional_extension_properties = {}
    }
  }

  # SensitiveDataDiscovery extension
  dynamic "extension" {
    for_each = var.cspm_sensitive_data_enabled ? [1] : []
    content {
      name                            = "SensitiveDataDiscovery"
      additional_extension_properties = {}
    }
  }
}

# --- MDE Policy Definitions (Data Sources) ---
data "azurerm_policy_definition" "mde_win" {
  count = var.enable_mde_policies ? 1 : 0
  name  = var.mde_win_policy_definition
}

data "azurerm_policy_definition" "mde_lin" {
  count = var.enable_mde_policies ? 1 : 0
  name  = var.mde_lin_policy_definition
}

locals {
  subscription_scope = "/subscriptions/${trimprefix(var.subscription_id, "/subscriptions/")}"
}

# MDE Extension Policy for Windows
resource "azurerm_subscription_policy_assignment" "mde_windows" {
  count                = var.enable_mde_policies ? 1 : 0
  name                 = "configure-mde-windows"
  subscription_id      = local.subscription_scope
  policy_definition_id = data.azurerm_policy_definition.mde_win[0].id
  location             = var.mde_windows_policy_location

  identity {
    type = "SystemAssigned"
  }
}

# MDE Extension Policy for Linux
resource "azurerm_subscription_policy_assignment" "mde_linux" {
  count                = var.enable_mde_policies ? 1 : 0
  name                 = "configure-mde-linux"
  subscription_id      = local.subscription_scope
  policy_definition_id = data.azurerm_policy_definition.mde_lin[0].id
  location             = var.mde_linux_policy_location

  identity {
    type = "SystemAssigned"
  }
}

# --- MDE Policy Role Assignments ---
resource "azurerm_role_assignment" "mde_win_contrib" {
  count                = var.enable_mde_policies ? 1 : 0
  scope                = local.subscription_scope
  role_definition_name = "Contributor"
  principal_id         = azurerm_subscription_policy_assignment.mde_windows[0].identity[0].principal_id
}

resource "azurerm_role_assignment" "mde_lin_contrib" {
  count                = var.enable_mde_policies ? 1 : 0
  scope                = local.subscription_scope
  role_definition_name = "Contributor"
  principal_id         = azurerm_subscription_policy_assignment.mde_linux[0].identity[0].principal_id
}

# --- MDE Policy Remediations ---
resource "azurerm_subscription_policy_remediation" "mde_win" {
  count                   = var.enable_mde_policies && var.enable_mde_remediation ? 1 : 0
  name                    = "remediate-mde-windows"
  subscription_id         = local.subscription_scope
  policy_assignment_id    = azurerm_subscription_policy_assignment.mde_windows[0].id
  resource_discovery_mode = "ExistingNonCompliant"
  parallel_deployments    = var.remediation_parallel_deployments
  failure_percentage      = var.remediation_failure_percentage
}

resource "azurerm_subscription_policy_remediation" "mde_lin" {
  count                   = var.enable_mde_policies && var.enable_mde_remediation ? 1 : 0
  name                    = "remediate-mde-linux"
  subscription_id         = local.subscription_scope
  policy_assignment_id    = azurerm_subscription_policy_assignment.mde_linux[0].id
  resource_discovery_mode = "ExistingNonCompliant"
  parallel_deployments    = var.remediation_parallel_deployments
  failure_percentage      = var.remediation_failure_percentage
}

# --- HIPAA HITRUST Policy Set Definition (Data Source) ---
data "azurerm_policy_set_definition" "hipaa_hitrust" {
  count = var.enable_hipaa_policy ? 1 : 0
  name  = var.hipaa_policy_set_definition
}

# Role definitions for HIPAA policy assignment
data "azurerm_role_definition" "resource_policy_contributor" {
  count = var.enable_hipaa_policy ? 1 : 0
  name  = "Resource Policy Contributor"
  scope = "/subscriptions/${var.subscription_id}"
}

data "azurerm_role_definition" "contributor" {
  count = var.enable_hipaa_policy ? 1 : 0
  name  = "Contributor"
  scope = "/subscriptions/${var.subscription_id}"
}

# HIPAA HITRUST Policy Assignment
resource "azurerm_subscription_policy_assignment" "hipaa" {
  count                = var.enable_hipaa_policy ? 1 : 0
  name                 = "hipaa-hitrust"
  subscription_id      = "/subscriptions/${var.subscription_id}"
  policy_definition_id = data.azurerm_policy_set_definition.hipaa_hitrust[0].id
  location             = var.hipaa_policy_location

  identity {
    type = "SystemAssigned"
  }
}

# HIPAA Policy Role Assignments
resource "azurerm_role_assignment" "hipaa_policy_contrib" {
  count                            = var.enable_hipaa_policy ? 1 : 0
  scope                            = "/subscriptions/${var.subscription_id}"
  role_definition_id               = data.azurerm_role_definition.resource_policy_contributor[0].role_definition_id
  principal_id                     = azurerm_subscription_policy_assignment.hipaa[0].identity[0].principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "hipaa_contrib" {
  count                            = var.enable_hipaa_policy ? 1 : 0
  scope                            = "/subscriptions/${var.subscription_id}"
  role_definition_id               = data.azurerm_role_definition.contributor[0].role_definition_id
  principal_id                     = azurerm_subscription_policy_assignment.hipaa[0].identity[0].principal_id
  skip_service_principal_aad_check = true
}

# Security Admin Role Assignments (for additional principals)
resource "azurerm_role_assignment" "security_admin" {
  count                = length(var.security_admin_principal_ids)
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Security Admin"
  principal_id         = var.security_admin_principal_ids[count.index]
}
