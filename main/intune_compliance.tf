# =============================================================================
# Intune — Windows 10/11 Compliance Policy ("AcmeHealth")
#
# Provider: deploymenttheory/microsoft365 (~> 0.48)
#
# BEFORE FIRST APPLY:
# 1. Update the import block with the actual policy GUID (already set below).
# 2. Add M365_TENANT_ID, M365_CLIENT_ID, M365_AUTH_METHOD=github_oidc to the
#    workflow env alongside the existing ARM_* variables.
# 3. Grant the deploy SP these Graph API permissions (app permissions):
#      DeviceManagementConfiguration.ReadWrite.All
#      Directory.Read.All
# 4. Run: terraform init && terraform plan
#    Verify no unexpected drift on existing settings before applying.
# =============================================================================

import {
  id = "40eb225b-4733-4827-9b3a-50bd65ce9e13"
  to = microsoft365_graph_beta_device_management_windows_device_compliance_policy.acme-health
}

resource "microsoft365_graph_beta_device_management_windows_device_compliance_policy" "acme-health" {
  display_name = "AcmeHealth"
  description  = "Windows 10/11 device compliance policy for AcmeHealth Group — HIPAA baseline"

  # ---------------------------------------------------------------------------
  # Device Health — existing settings, verify after import
  # ---------------------------------------------------------------------------
  device_health = {
    bit_locker_enabled     = true
    secure_boot_enabled    = true
    code_integrity_enabled = true
  }

  # ---------------------------------------------------------------------------
  # Device Properties
  # NEW: os_minimum_version — Windows 10 22H2 (build 10.0.19045)
  # Devices below this build are out of support and missing security patches.
  # ---------------------------------------------------------------------------
  device_properties = {
    os_minimum_version = "10.0.19045.0"
  }

  # ---------------------------------------------------------------------------
  # System Security — existing password settings + three new controls
  # Verify password values match actual Intune policy after import.
  # ---------------------------------------------------------------------------
  system_security = {
    # Existing password settings
    password_required                          = true
    password_block_simple                      = true
    password_required_type                     = "alphanumeric"
    password_minimum_length                    = 12
    password_minimum_character_set_count       = 4
    password_minutes_of_inactivity_before_lock = 15
    password_expiration_days                   = 90
    password_previous_password_block_count     = 10
    password_required_to_unlock_from_idle      = true

    # NEW: Require TPM chip — hardware-based key protection
    tpm_required = true

    # NEW: Require Microsoft Defender Antivirus active and reporting healthy
    antivirus_required = true
    defender_enabled   = true
  }

  # ---------------------------------------------------------------------------
  # Scheduled action — required by provider; mark non-compliant immediately
  # ---------------------------------------------------------------------------
  scheduled_actions_for_rule = [
    {
      scheduled_action_configurations = [
        {
          action_type        = "block"
          grace_period_hours = 0
        }
      ]
    }
  ]
}

# =============================================================================
# Default Device Compliance Policy Setting
#
# The deploymenttheory/microsoft365 provider (v0.48.x) does not expose the
# tenant-wide "mark devices with no compliance policy as" setting as a resource.
#
# ACTION REQUIRED — set manually in Intune portal:
#   Intune > Devices > Compliance policies > Compliance policy settings
#   "Mark devices with no compliance policy as" → Not compliant
#
# Graph API equivalent (PowerShell/script):
#   PATCH https://graph.microsoft.com/beta/deviceManagement/deviceCompliancePolicies/defaultDeviceCompliancePolicy
#   Body: { "defaultDeviceCompliancePolicyEnforcement": "NonCompliant" }
# =============================================================================
