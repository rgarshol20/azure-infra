# Defender for Cloud - Module Adoption (Light Pattern: CSPM + HIPAA only)
module "defender" {
  source    = "../modules/defender"
  providers = { azurerm = azurerm }

  subscription_id                    = var.main_subscription_id
  enable_defender_for_servers        = false
  enable_defender_cspm               = true
  cspm_agentless_vm_scanning_enabled = true
  cspm_agentless_k8s_enabled         = true
  cspm_container_va_enabled          = true
  cspm_entra_permissions_enabled     = true
  cspm_sensitive_data_enabled        = true
  enable_mde_policies                = false
  enable_hipaa_policy                = true
  hipaa_policy_set_definition        = var.hitrust_assessment_name
  hipaa_policy_location              = "westus2"
  tags                               = local.required_tags
}

# Moved blocks for zero-downtime migration
moved {
  from = azurerm_security_center_subscription_pricing.cspm
  to   = module.defender.azurerm_security_center_subscription_pricing.cspm[0]
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

# Defender for Resource Manager
resource "azurerm_security_center_subscription_pricing" "arm" {
  tier          = "Standard"
  resource_type = "Arm"
  subplan       = "PerSubscription"
}

# Defender for Storage V2 with Malware Scanning + Sensitive Data Discovery
# NOTE: OnUploadMalwareScanning incurs per-GB scan cost (~$0.15/GB). Enable intentionally.
resource "azurerm_security_center_subscription_pricing" "storage" {
  tier          = "Standard"
  resource_type = "StorageAccounts"
  subplan       = "DefenderForStorageV2"

  extension {
    name = "OnUploadMalwareScanning"
  }

  extension {
    name = "SensitiveDataDiscovery"
  }
}

# Security contact is managed out-of-band (not via Terraform).
# The azurerm v4 provider uses a newer API version (2023-12-01-preview) that cannot read the
# pre-existing v1 "default" contact, causing import to fail with "non-existent remote object".
# The contact (name=default, email=admin@acme-health.com, alerts+admin notifications enabled)
# already exists and is correctly configured in Azure — no action required.
# #checkov:skip=CKV_AZURE_20:Security contact exists and is configured correctly out-of-band
