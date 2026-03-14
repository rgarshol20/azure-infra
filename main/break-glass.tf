# =============================================================================
# Break Glass Emergency Access Accounts — Production Tenant
#
# Purpose: Cloud-only emergency access accounts that bypass all CA policies.
# Required BEFORE creating any Conditional Access policies (Maester MT.1005).
#
# Reference: https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/security-emergency-access
#
# AFTER APPLY — Required manual steps:
#   1. Run: terraform output -raw break_glass_1_password  → print + store in physical safe
#   2. Run: terraform output -raw break_glass_2_password  → print + store in physical safe
#   3. Enable Entra sign-in logs → Log Analytics (one-time, see alert section below)
#   4. Add CA-Exclusion-BreakGlass group to EVERY existing CA policy exclusion list
#   5. Test both accounts can sign in from a non-primary device
# =============================================================================

# Dynamically resolve the initial .onmicrosoft.com domain (cloud-only, not federated)
data "azuread_domains" "initial" {
  only_initial = true
}

# =============================================================================
# Passwords — 32-char random, stored in encrypted Terraform state (S3 backend)
# Retrieve once: terraform output -raw break_glass_1_password
# Store: printed copy in physical safe + offline password manager
# =============================================================================
resource "random_password" "break_glass_1" {
  length           = 32
  special          = true
  override_special = "!@#$%&*()-_=+[]{}|;:,.<>?"
  min_special      = 4
  min_upper        = 4
  min_lower        = 4
  min_numeric      = 4
}

resource "random_password" "break_glass_2" {
  length           = 32
  special          = true
  override_special = "!@#$%&*()-_=+[]{}|;:,.<>?"
  min_special      = 4
  min_upper        = 4
  min_lower        = 4
  min_numeric      = 4
}

# =============================================================================
# Users — cloud-only (.onmicrosoft.com UPN avoids custom domain / federation dependency)
# No immutable_id set = cloud-only account, never synced from on-prem
# force_password_change = false — passwords must work immediately in emergencies
# =============================================================================
resource "azuread_user" "break_glass_1" {
  user_principal_name   = "break-glass-1@${data.azuread_domains.initial.domains[0].domain_name}"
  display_name          = "Break Glass Admin 1"
  mail_nickname         = "break-glass-1"
  password              = random_password.break_glass_1.result
  force_password_change = false
  account_enabled       = true
}

resource "azuread_user" "break_glass_2" {
  user_principal_name   = "break-glass-2@${data.azuread_domains.initial.domains[0].domain_name}"
  display_name          = "Break Glass Admin 2"
  mail_nickname         = "break-glass-2"
  password              = random_password.break_glass_2.result
  force_password_change = false
  account_enabled       = true
}

# =============================================================================
# CA Exclusion Group
# Add this group to the Exclusions tab of EVERY Conditional Access policy.
# The object_id output below makes this easy to reference.
# =============================================================================
resource "azuread_group" "break_glass_exclusion" {
  display_name     = "CA-Exclusion-BreakGlass"
  description      = "Emergency access accounts excluded from all Conditional Access policies. Never remove members or delete this group."
  security_enabled = true
  mail_enabled     = false
}

resource "azuread_group_member" "break_glass_1" {
  group_object_id  = azuread_group.break_glass_exclusion.object_id
  member_object_id = azuread_user.break_glass_1.object_id
}

resource "azuread_group_member" "break_glass_2" {
  group_object_id  = azuread_group.break_glass_exclusion.object_id
  member_object_id = azuread_user.break_glass_2.object_id
}

# =============================================================================
# Global Administrator — permanent assignment (NOT PIM eligible, intentional)
# Break glass must work even if PIM, MFA, or Azure AD is degraded.
# =============================================================================
resource "azuread_directory_role" "global_admin" {
  display_name = "Global Administrator"
}

resource "azuread_directory_role_assignment" "break_glass_1_global_admin" {
  role_id             = azuread_directory_role.global_admin.template_id
  principal_object_id = azuread_user.break_glass_1.object_id
}

resource "azuread_directory_role_assignment" "break_glass_2_global_admin" {
  role_id             = azuread_directory_role.global_admin.template_id
  principal_object_id = azuread_user.break_glass_2.object_id
}

# =============================================================================
# Sign-In Alerting
# Fires within 5 minutes of any successful break glass authentication.
#
# PREREQUISITE (one-time manual step if not already done):
#   Azure Portal → Microsoft Entra ID → Diagnostic settings → + Add diagnostic setting
#   → Check "SignInLogs" and "AuditLogs"
#   → Destination: Send to Log Analytics workspace → acme-health-main-law
#   → Save
#
# After enabling, SigninLogs table populates within ~15 minutes.
# =============================================================================
resource "azurerm_monitor_action_group" "break_glass_alerts" {
  name                = "ag-break-glass-signin"
  resource_group_name = azurerm_resource_group.logging.name
  short_name          = "bg-alert"

  email_receiver {
    name                    = "admin"
    email_address           = "admin@acme-health.com"
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "break_glass_signin" {
  name                = "alert-break-glass-signin"
  location            = var.location
  resource_group_name = azurerm_resource_group.logging.name
  description         = "CRITICAL: A break glass emergency access account has signed in. Investigate immediately."
  enabled             = true
  severity            = 0 # Critical

  evaluation_frequency = "PT5M" # Evaluate every 5 minutes
  window_duration      = "PT5M" # Look back 5 minutes

  scopes = [azurerm_log_analytics_workspace.local_law.id]

  criteria {
    query = <<-QUERY
      SigninLogs
      | where UserPrincipalName in (
          "break-glass-1@${data.azuread_domains.initial.domains[0].domain_name}",
          "break-glass-2@${data.azuread_domains.initial.domains[0].domain_name}"
        )
      | where ResultType == "0"
      | project TimeGenerated, UserPrincipalName, IPAddress, Location, AppDisplayName, ClientAppUsed
    QUERY

    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.break_glass_alerts.id]
    custom_properties = {
      "AlertType" = "BreakGlassSignIn"
      "Severity"  = "CRITICAL"
    }
  }
}

# =============================================================================
# Outputs
# =============================================================================
output "break_glass_1_upn" {
  value       = azuread_user.break_glass_1.user_principal_name
  description = "Break glass account 1 UPN"
}

output "break_glass_2_upn" {
  value       = azuread_user.break_glass_2.user_principal_name
  description = "Break glass account 2 UPN"
}

output "break_glass_1_password" {
  value       = random_password.break_glass_1.result
  description = "Break glass 1 password — run: terraform output -raw break_glass_1_password"
  sensitive   = true
}

output "break_glass_2_password" {
  value       = random_password.break_glass_2.result
  description = "Break glass 2 password — run: terraform output -raw break_glass_2_password"
  sensitive   = true
}

output "break_glass_exclusion_group_id" {
  value       = azuread_group.break_glass_exclusion.object_id
  description = "CA exclusion group object ID — add to ALL CA policy exclusion lists"
}
