# Defender for Cloud — MCSB Policy Exemptions
#
# These exemptions waive specific policies within the SecurityCenterBuiltIn (MCSB)
# initiative for controls that either do not apply to our environment or are
# intentional architectural decisions with accepted risk.
#
# Initiative: Microsoft Cloud Security Benchmark (1f3afdf9-d0c9-4c3d-847f-89da613e70a8)
# Assignment: SecurityCenterBuiltIn (per-subscription, Defender auto-deployed)
#
# Subscriptions covered: prod only.
# The main subscription (var.main_subscription_id) does NOT have a
# SecurityCenterBuiltIn assignment — only the prod subscription does.
# Firewall subscription also does not have a SecurityCenterBuiltIn assignment.
#
# Native Defender assessments NOT backed by Azure Policy — cannot be exempted here;
# use Defender for Cloud portal to suppress per-resource:
#   - "Only approved VM extensions should be installed" (6a170dc2)
#   - "Service Principals should not be assigned with administrative roles" (effc9a76)

locals {
  mcsb_assignment_prod = "/subscriptions/${var.prod_subscription_id}/providers/Microsoft.Authorization/policyAssignments/SecurityCenterBuiltIn"

  # Policies that do not apply to Palo Alto / vendor-managed appliances.
  # PA Firewall and Panorama are vendor appliances: no domain join, no Azure Backup,
  # no SSH key enforcement (vendor manages auth), encryption-at-host unsupported on
  # the underlying hardware (risk accepted per PA hardware requirements).
  vendor_appliance_policy_ids = [
    "windowsGuestConfigBaselinesMonitoring",
    "linuxGuestConfigBaselinesMonitoring",
    "GuestAttestationExtensionShouldBeInstalledOnSupportedWindowsVirtualMachinesMonitoringEffect",
    "GuestAttestationExtensionShouldBeInstalledOnSupportedLinuxVirtualMachinesMonitoringEffect",
    "authenticationToLinuxMachinesShouldRequireSSHKeysMonitoringEffect",
    "azureBackupShouldBeEnabledForVirtualMachinesMonitoringEffect",
    "virtualMachinesAndVirtualMachineScaleSetsShouldHaveEncryptionAtHostEnabled",
  ]

  # Policies waived as intentional architectural decisions with accepted risk.
  # KV private link: KVs are network-restricted via ACLs; private endpoint adds
  #   complexity without meaningful additional security in this topology.
  # Custom RBAC: Terraform deploy SP requires a custom role scoped to only what
  #   IaC needs — using built-in Owner/Contributor would be broader, not narrower.
  architectural_policy_ids = [
    "privateEndpointShouldBeConfiguredForKeyVaultMonitoringEffect",
    "useRbacRulesMonitoring",
  ]
}

# ---------------------------------------------------------------------------
# Prod subscription (only subscription with SecurityCenterBuiltIn assignment)
# ---------------------------------------------------------------------------

resource "azurerm_subscription_policy_exemption" "mcsb_vendor_appliances_prod" {
  provider = azurerm.prod

  name                 = "mcsb-vendor-appliances-prod"
  subscription_id      = "/subscriptions/${var.prod_subscription_id}"
  policy_assignment_id = local.mcsb_assignment_prod
  exemption_category   = "Waiver"
  display_name         = "MCSB vendor appliance exemptions — prod subscription"
  description          = "Palo Alto Firewall and Panorama are vendor-managed appliances. Guest Config baselines, SSH key enforcement, Azure Backup, and encryption-at-host do not apply. Risk accepted per vendor hardware requirements."

  policy_definition_reference_ids = local.vendor_appliance_policy_ids
}

resource "azurerm_subscription_policy_exemption" "mcsb_architectural_decisions_prod" {
  provider = azurerm.prod

  name                 = "mcsb-architectural-decisions-prod"
  subscription_id      = "/subscriptions/${var.prod_subscription_id}"
  policy_assignment_id = local.mcsb_assignment_prod
  exemption_category   = "Waiver"
  display_name         = "MCSB architectural decision exemptions — prod subscription"
  description          = "KV private link: network ACLs provide equivalent isolation in this topology. Custom RBAC: Terraform deploy SP uses a least-privilege custom role — built-in roles would grant broader permissions."

  policy_definition_reference_ids = local.architectural_policy_ids
}
