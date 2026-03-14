# Defender for Cloud - Module Adoption
module "defender" {
  source    = "../modules/defender"
  providers = { azurerm = azurerm.identity }

  subscription_id                    = var.identity_subscription_id
  enable_defender_for_servers        = true
  defender_servers_subplan           = "P2"
  enable_defender_cspm               = true
  cspm_agentless_vm_scanning_enabled = true
  cspm_agentless_k8s_enabled         = true
  cspm_container_va_enabled          = true
  cspm_entra_permissions_enabled     = true
  cspm_sensitive_data_enabled        = true
  enable_mde_policies                = true
  mde_win_policy_definition          = var.mde_win
  mde_lin_policy_definition          = var.mde_lin
  mde_windows_policy_location        = var.location
  mde_linux_policy_location          = var.location
  enable_hipaa_policy                = true
  hipaa_policy_set_definition        = var.hitrust_assessment_name
  hipaa_policy_location              = "westus2"
  tags                               = local.required_tags
}

# Moved blocks for zero-downtime migration
moved {
  from = azurerm_security_center_subscription_pricing.servers
  to   = module.defender.azurerm_security_center_subscription_pricing.servers[0]
}

moved {
  from = azurerm_security_center_subscription_pricing.cspm
  to   = module.defender.azurerm_security_center_subscription_pricing.cspm[0]
}

moved {
  from = azurerm_subscription_policy_assignment.mde_win
  to   = module.defender.azurerm_subscription_policy_assignment.mde_windows[0]
}

moved {
  from = azurerm_subscription_policy_assignment.mde_lin
  to   = module.defender.azurerm_subscription_policy_assignment.mde_linux[0]
}

moved {
  from = azurerm_role_assignment.mde_win_contrib
  to   = module.defender.azurerm_role_assignment.mde_win_contrib[0]
}

moved {
  from = azurerm_role_assignment.mde_lin_contrib
  to   = module.defender.azurerm_role_assignment.mde_lin_contrib[0]
}

moved {
  from = azurerm_subscription_policy_remediation.mde_win
  to   = module.defender.azurerm_subscription_policy_remediation.mde_win[0]
}

moved {
  from = azurerm_subscription_policy_remediation.mde_lin
  to   = module.defender.azurerm_subscription_policy_remediation.mde_lin[0]
}

moved {
  from = azurerm_subscription_policy_assignment.hipaa_hitrust
  to   = module.defender.azurerm_subscription_policy_assignment.hipaa[0]
}

moved {
  from = azurerm_role_assignment.hipaa_policy_contrib
  to   = module.defender.azurerm_role_assignment.hipaa_policy_contrib[0]
}

moved {
  from = azurerm_role_assignment.hipaa_contrib
  to   = module.defender.azurerm_role_assignment.hipaa_contrib[0]
}

# Defender for Key Vault
resource "azurerm_security_center_subscription_pricing" "key_vault" {
  provider      = azurerm.identity
  tier          = "Standard"
  resource_type = "KeyVaults"
  subplan       = "PerKeyVault"
}

# Defender for Resource Manager
resource "azurerm_security_center_subscription_pricing" "arm" {
  provider      = azurerm.identity
  tier          = "Standard"
  resource_type = "Arm"
  subplan       = "PerSubscription"
}

# Defender for Storage V2 with Malware Scanning + Sensitive Data Discovery
resource "azurerm_security_center_subscription_pricing" "storage" {
  provider      = azurerm.identity
  tier          = "Standard"
  resource_type = "StorageAccounts"
  subplan       = "DefenderForStorageV2"

  extension {
    name = "SensitiveDataDiscovery"
  }
}
