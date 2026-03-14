# CIS Azure Benchmark 5.1.x — Activity Log Alerts (Dashboard subscription)
# Satisfies Defender recommendations for specific Administrative, Security, and Policy operations.

resource "azurerm_monitor_action_group" "security_ops_alerts" {
  provider            = azurerm.dashboard
  name                = "ag-security-ops-alerts"
  resource_group_name = azurerm_resource_group.logging.name
  short_name          = "sec-ops"

  email_receiver {
    name                    = "security-admin"
    email_address           = "admin@acme-health.com"
    use_common_alert_schema = true
  }

  tags = local.required_tags
}

# NSG create/update (CIS 5.1.3)
resource "azurerm_monitor_activity_log_alert" "nsg_write" {
  provider            = azurerm.dashboard
  name                = "alert-nsg-create-update"
  resource_group_name = azurerm_resource_group.logging.name
  location            = "Global"
  description         = "Alert on Network Security Group create or update operations"
  scopes              = ["/subscriptions/${var.dashboard_subscription_id}"]
  enabled             = true

  criteria {
    category       = "Administrative"
    operation_name = "Microsoft.Network/networkSecurityGroups/write"
  }

  action {
    action_group_id = azurerm_monitor_action_group.security_ops_alerts.id
  }

  tags = local.required_tags
}

# NSG delete (CIS 5.1.4)
resource "azurerm_monitor_activity_log_alert" "nsg_delete" {
  provider            = azurerm.dashboard
  name                = "alert-nsg-delete"
  resource_group_name = azurerm_resource_group.logging.name
  location            = "Global"
  description         = "Alert on Network Security Group delete operations"
  scopes              = ["/subscriptions/${var.dashboard_subscription_id}"]
  enabled             = true

  criteria {
    category       = "Administrative"
    operation_name = "Microsoft.Network/networkSecurityGroups/delete"
  }

  action {
    action_group_id = azurerm_monitor_action_group.security_ops_alerts.id
  }

  tags = local.required_tags
}

# NSG rule create/update (CIS 5.1.5)
resource "azurerm_monitor_activity_log_alert" "nsg_rule_write" {
  provider            = azurerm.dashboard
  name                = "alert-nsg-rule-create-update"
  resource_group_name = azurerm_resource_group.logging.name
  location            = "Global"
  description         = "Alert on Network Security Group rule create or update operations"
  scopes              = ["/subscriptions/${var.dashboard_subscription_id}"]
  enabled             = true

  criteria {
    category       = "Administrative"
    operation_name = "Microsoft.Network/networkSecurityGroups/securityRules/write"
  }

  action {
    action_group_id = azurerm_monitor_action_group.security_ops_alerts.id
  }

  tags = local.required_tags
}

# NSG rule delete (CIS 5.1.6)
resource "azurerm_monitor_activity_log_alert" "nsg_rule_delete" {
  provider            = azurerm.dashboard
  name                = "alert-nsg-rule-delete"
  resource_group_name = azurerm_resource_group.logging.name
  location            = "Global"
  description         = "Alert on Network Security Group rule delete operations"
  scopes              = ["/subscriptions/${var.dashboard_subscription_id}"]
  enabled             = true

  criteria {
    category       = "Administrative"
    operation_name = "Microsoft.Network/networkSecurityGroups/securityRules/delete"
  }

  action {
    action_group_id = azurerm_monitor_action_group.security_ops_alerts.id
  }

  tags = local.required_tags
}

# Security solution create/update (CIS 5.1.7)
resource "azurerm_monitor_activity_log_alert" "security_solution_write" {
  provider            = azurerm.dashboard
  name                = "alert-security-solution-create-update"
  resource_group_name = azurerm_resource_group.logging.name
  location            = "Global"
  description         = "Alert on security solution create or update operations"
  scopes              = ["/subscriptions/${var.dashboard_subscription_id}"]
  enabled             = true

  criteria {
    category       = "Administrative"
    operation_name = "Microsoft.Security/securitySolutions/write"
  }

  action {
    action_group_id = azurerm_monitor_action_group.security_ops_alerts.id
  }

  tags = local.required_tags
}

# Security solution delete (CIS 5.1.8)
resource "azurerm_monitor_activity_log_alert" "security_solution_delete" {
  provider            = azurerm.dashboard
  name                = "alert-security-solution-delete"
  resource_group_name = azurerm_resource_group.logging.name
  location            = "Global"
  description         = "Alert on security solution delete operations"
  scopes              = ["/subscriptions/${var.dashboard_subscription_id}"]
  enabled             = true

  criteria {
    category       = "Administrative"
    operation_name = "Microsoft.Security/securitySolutions/delete"
  }

  action {
    action_group_id = azurerm_monitor_action_group.security_ops_alerts.id
  }

  tags = local.required_tags
}

# SQL Server firewall rule create/update (CIS 5.1.9)
resource "azurerm_monitor_activity_log_alert" "sql_firewall_write" {
  provider            = azurerm.dashboard
  name                = "alert-sql-firewall-create-update"
  resource_group_name = azurerm_resource_group.logging.name
  location            = "Global"
  description         = "Alert on SQL Server firewall rule create or update operations"
  scopes              = ["/subscriptions/${var.dashboard_subscription_id}"]
  enabled             = true

  criteria {
    category       = "Administrative"
    operation_name = "Microsoft.Sql/servers/firewallRules/write"
  }

  action {
    action_group_id = azurerm_monitor_action_group.security_ops_alerts.id
  }

  tags = local.required_tags
}

# SQL Server firewall rule delete (CIS 5.1.10)
resource "azurerm_monitor_activity_log_alert" "sql_firewall_delete" {
  provider            = azurerm.dashboard
  name                = "alert-sql-firewall-delete"
  resource_group_name = azurerm_resource_group.logging.name
  location            = "Global"
  description         = "Alert on SQL Server firewall rule delete operations"
  scopes              = ["/subscriptions/${var.dashboard_subscription_id}"]
  enabled             = true

  criteria {
    category       = "Administrative"
    operation_name = "Microsoft.Sql/servers/firewallRules/delete"
  }

  action {
    action_group_id = azurerm_monitor_action_group.security_ops_alerts.id
  }

  tags = local.required_tags
}

# Policy assignment create/update (CIS 5.1.1)
resource "azurerm_monitor_activity_log_alert" "policy_write" {
  provider            = azurerm.dashboard
  name                = "alert-policy-assignment-create-update"
  resource_group_name = azurerm_resource_group.logging.name
  location            = "Global"
  description         = "Alert on policy assignment create or update operations"
  scopes              = ["/subscriptions/${var.dashboard_subscription_id}"]
  enabled             = true

  criteria {
    category       = "Administrative"
    operation_name = "Microsoft.Authorization/policyAssignments/write"
  }

  action {
    action_group_id = azurerm_monitor_action_group.security_ops_alerts.id
  }

  tags = local.required_tags
}

# Policy assignment delete (CIS 5.1.2)
resource "azurerm_monitor_activity_log_alert" "policy_delete" {
  provider            = azurerm.dashboard
  name                = "alert-policy-assignment-delete"
  resource_group_name = azurerm_resource_group.logging.name
  location            = "Global"
  description         = "Alert on policy assignment delete operations"
  scopes              = ["/subscriptions/${var.dashboard_subscription_id}"]
  enabled             = true

  criteria {
    category       = "Administrative"
    operation_name = "Microsoft.Authorization/policyAssignments/delete"
  }

  action {
    action_group_id = azurerm_monitor_action_group.security_ops_alerts.id
  }

  tags = local.required_tags
}
