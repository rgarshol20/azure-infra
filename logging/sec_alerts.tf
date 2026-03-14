# =============================================================================
# Comprehensive Alert Package — Production Tenant
# Tier 1: Security & Compliance
# Tier 2: Operational
# Tier 3: Identity & Data Protection
# =============================================================================

# =============================================================================
# Shared Action Group
# =============================================================================
resource "azurerm_monitor_action_group" "critical_security" {
  provider            = azurerm.logging
  name                = "ag-critical-security"
  resource_group_name = azurerm_resource_group.logging.name
  short_name          = "CritSec"

  email_receiver {
    name          = "it-security"
    email_address = "admin@acme-health.com"
  }

  tags = local.required_tags
}

# =============================================================================
# TIER 1 — Security & Compliance
# =============================================================================

# 1. Break Glass Account Sign-In
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "breakglass_signin" {
  provider            = azurerm.logging
  name                = "alert-breakglass-signin"
  resource_group_name = azurerm_resource_group.logging.name
  location            = var.location
  description         = "CRITICAL: Break glass emergency access account sign-in detected"
  severity            = 0

  scopes = [azurerm_log_analytics_workspace.central_law.id]

  criteria {
    query = <<-KQL
      SigninLogs
      | where UserPrincipalName in ("breakglass1@acme-health.com", "breakglass2@acme-health.com")
    KQL

    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0
  }

  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"

  action {
    action_groups = [azurerm_monitor_action_group.critical_security.id]
  }

  enabled = true
  tags    = local.required_tags
}

# 2. Global Admin Role Assigned
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "global_admin_assigned" {
  provider            = azurerm.logging
  name                = "alert-global-admin-assigned"
  resource_group_name = azurerm_resource_group.logging.name
  location            = var.location
  description         = "CRITICAL: Global Administrator role was assigned to a user"
  severity            = 0

  scopes = [azurerm_log_analytics_workspace.central_law.id]

  criteria {
    query = <<-KQL
      AuditLogs
      | where OperationName == "Add member to role"
      | mv-expand TargetResources
      | mv-expand TargetResources.modifiedProperties
      | where TargetResources_modifiedProperties.displayName == "Role.DisplayName"
      | where TargetResources_modifiedProperties.newValue has "Global Administrator"
    KQL

    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0
  }

  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"

  action {
    action_groups = [azurerm_monitor_action_group.critical_security.id]
  }

  enabled = true
  tags    = local.required_tags
}

# 3. Conditional Access Policy Modified or Deleted
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "ca_policy_changed" {
  provider            = azurerm.logging
  name                = "alert-ca-policy-changed"
  resource_group_name = azurerm_resource_group.logging.name
  location            = var.location
  description         = "HIGH: Conditional Access policy was modified or deleted"
  severity            = 1

  scopes = [azurerm_log_analytics_workspace.central_law.id]

  criteria {
    query = <<-KQL
      AuditLogs
      | where Category == "Policy"
      | where OperationName has_any ("Update conditional access policy", "Delete conditional access policy")
    KQL

    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0
  }

  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"

  action {
    action_groups = [azurerm_monitor_action_group.critical_security.id]
  }

  enabled = true
  tags    = local.required_tags
}

# 4. Backup Job Failed
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "backup_job_failed" {
  provider            = azurerm.logging
  name                = "alert-backup-job-failed"
  resource_group_name = azurerm_resource_group.logging.name
  location            = var.location
  description         = "HIGH: Azure Backup job failed — recovery capability at risk"
  severity            = 1

  scopes = [azurerm_log_analytics_workspace.central_law.id]

  criteria {
    query = <<-KQL
      AzureDiagnostics
      | where Category == "AzureBackupReport"
      | where OperationName == "Job"
      | where ResultType == "Failed"
    KQL

    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0
  }

  evaluation_frequency = "PT30M"
  window_duration      = "PT30M"

  action {
    action_groups = [azurerm_monitor_action_group.critical_security.id]
  }

  enabled = true
  tags    = local.required_tags
}

# =============================================================================
# TIER 2 — Operational
# =============================================================================

# 5. VM Stopped or Deallocated
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "vm_deallocated" {
  provider            = azurerm.logging
  name                = "alert-vm-deallocated"
  resource_group_name = azurerm_resource_group.logging.name
  location            = var.location
  description         = "WARNING: Virtual machine was stopped or deallocated"
  severity            = 2

  scopes = [azurerm_log_analytics_workspace.central_law.id]

  criteria {
    query = <<-KQL
      AzureActivity
      | where OperationNameValue has "Microsoft.Compute/virtualMachines/deallocate/action"
      | where ActivityStatusValue == "Success"
    KQL

    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0
  }

  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"

  action {
    action_groups = [azurerm_monitor_action_group.critical_security.id]
  }

  enabled = true
  tags    = local.required_tags
}

# 6. Key Vault Access Denied
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "keyvault_access_denied" {
  provider            = azurerm.logging
  name                = "alert-keyvault-access-denied"
  resource_group_name = azurerm_resource_group.logging.name
  location            = var.location
  description         = "WARNING: Key Vault access denied — possible unauthorized access attempt"
  severity            = 2

  scopes = [azurerm_log_analytics_workspace.central_law.id]

  criteria {
    query = <<-KQL
      AzureDiagnostics
      | where ResourceProvider == "MICROSOFT.KEYVAULT"
      | where ResultSignature has "Forbidden"
    KQL

    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 5
  }

  evaluation_frequency = "PT15M"
  window_duration      = "PT15M"

  action {
    action_groups = [azurerm_monitor_action_group.critical_security.id]
  }

  enabled = true
  tags    = local.required_tags
}

# 7. NSG Rule Modified
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "nsg_modified" {
  provider            = azurerm.logging
  name                = "alert-nsg-modified"
  resource_group_name = azurerm_resource_group.logging.name
  location            = var.location
  description         = "WARNING: Network Security Group rule was modified"
  severity            = 2

  scopes = [azurerm_log_analytics_workspace.central_law.id]

  criteria {
    query = <<-KQL
      AzureActivity
      | where OperationNameValue has "Microsoft.Network/networkSecurityGroups/write"
      | where ActivityStatusValue == "Success"
    KQL

    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0
  }

  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"

  action {
    action_groups = [azurerm_monitor_action_group.critical_security.id]
  }

  enabled = true
  tags    = local.required_tags
}

# =============================================================================
# TIER 3 — Identity & Data Protection
# =============================================================================

# 8. Risky Sign-In Detected
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "risky_signin" {
  provider            = azurerm.logging
  name                = "alert-risky-signin"
  resource_group_name = azurerm_resource_group.logging.name
  location            = var.location
  description         = "HIGH: Medium or high risk sign-in detected by Entra Identity Protection"
  severity            = 1

  scopes = [azurerm_log_analytics_workspace.central_law.id]

  criteria {
    query = <<-KQL
      SigninLogs
      | where RiskLevelDuringSignIn in ("medium", "high")
      | where ResultType == 0
    KQL

    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0
  }

  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"

  action {
    action_groups = [azurerm_monitor_action_group.critical_security.id]
  }

  # NOTE: Requires Entra P2 for RiskLevelDuringSignIn to be populated.
  # Set enabled = false if P2 is not licensed.
  enabled = true
  tags    = local.required_tags
}

# 9. MFA Method Changed
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "mfa_method_changed" {
  provider            = azurerm.logging
  name                = "alert-mfa-method-changed"
  resource_group_name = azurerm_resource_group.logging.name
  location            = var.location
  description         = "HIGH: User authentication method was registered or modified"
  severity            = 1

  scopes = [azurerm_log_analytics_workspace.central_law.id]

  criteria {
    query = <<-KQL
      AuditLogs
      | where OperationName has_any (
          "User registered security info",
          "User deleted security info",
          "User changed default security info",
          "Admin registered security info",
          "Admin deleted security info"
        )
    KQL

    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0
  }

  evaluation_frequency = "PT15M"
  window_duration      = "PT15M"

  action {
    action_groups = [azurerm_monitor_action_group.critical_security.id]
  }

  enabled = true
  tags    = local.required_tags
}

# 10. Storage Account Public Access Changed
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "storage_public_access" {
  provider            = azurerm.logging
  name                = "alert-storage-public-access"
  resource_group_name = azurerm_resource_group.logging.name
  location            = var.location
  description         = "CRITICAL: Storage account public access setting was changed"
  severity            = 0

  scopes = [azurerm_log_analytics_workspace.central_law.id]

  criteria {
    query = <<-KQL
      AzureActivity
      | where OperationNameValue has "Microsoft.Storage/storageAccounts/write"
      | where ActivityStatusValue == "Success"
      | where Properties_d has "publicNetworkAccess"
    KQL

    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0
  }

  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"

  action {
    action_groups = [azurerm_monitor_action_group.critical_security.id]
  }

  enabled = true
  tags    = local.required_tags
}
