provider "azuread" {
  use_oidc = true # ADD THIS
}

# Retrieve current subscription/tenant info
data "azurerm_client_config" "current" {}

# Azure AD App Registration for GitHub OIDC
resource "azuread_application" "github_deploy_app" {
  provider     = azuread
  display_name = "github-deploy-app"
}

# Create the service principal for the app
resource "azuread_service_principal" "github_deploy_sp" {
  provider  = azuread
  client_id = azuread_application.github_deploy_app.client_id
}

# Federated Identity Credential for GitHub OIDC
resource "azuread_application_federated_identity_credential" "github_oidc" {
  application_id = azuread_application.github_deploy_app.id
  display_name   = "github-actions"
  description    = "Federated identity for GitHub Actions main branch"
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:AcmeHealthInc/azure-infra:ref:refs/heads/main"
  audiences      = ["api://AzureADTokenExchange"]
}

# Federated Identity Credential for ops-automation repository
resource "azuread_application_federated_identity_credential" "github_oidc_ops_automation" {
  application_id = azuread_application.github_deploy_app.id
  display_name   = "ops-automation-main"
  description    = "Federated identity for ops-automation cost workflow"
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:AcmeHealthInc/ops-automation:ref:refs/heads/main"
  audiences      = ["api://AzureADTokenExchange"]
}

# Storage Blob Data Contributor on Terraform state storage account
# Required for GitHub Actions SP to read/write backend state via OIDC + use_azuread_auth
resource "azurerm_role_assignment" "github_deploy_state_blob" {
  principal_id         = azuread_service_principal.github_deploy_sp.object_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = azurerm_storage_account.encrypted_storage.id
}

# # Contributor role on the Dev subscription
# resource "azurerm_role_assignment" "dev_contributor" {
#   principal_id         = azuread_service_principal.github_deploy_sp.object_id
#   role_definition_name = "Contributor"
#   scope                = "/subscriptions/${var.dev_subscription_id}"
# }

# # Contributor role on the Logging subscription
# resource "azurerm_role_assignment" "logging_contributor" {
#   principal_id         = azuread_service_principal.github_deploy_sp.object_id
#   role_definition_name = "Contributor"
#   scope                = "/subscriptions/${var.logging_subscription_id}"
# }

# # Contributor role on the Firewall subscription
# resource "azurerm_role_assignment" "firewall_contributor" {
#   principal_id         = azuread_service_principal.github_deploy_sp.object_id
#   role_definition_name = "Contributor"
#   scope                = "/subscriptions/${var.firewall_subscription_id}"
# }

# # Contributor role on the Identity subscription
# resource "azurerm_role_assignment" "identity_contributor" {
#   principal_id         = azuread_service_principal.github_deploy_sp.object_id
#   role_definition_name = "Contributor"
#   scope                = "/subscriptions/${var.identity_subscription_id}"
# }

# # Contributor role on the Prod subscription
# resource "azurerm_role_assignment" "prod_contributor" {
#   principal_id         = azuread_service_principal.github_deploy_sp.object_id
#   role_definition_name = "Contributor"
#   scope                = "/subscriptions/${var.prod_subscription_id}"
# }

# # Contributor role on the Main subscription
# resource "azurerm_role_assignment" "main_contributor" {
#   principal_id         = azuread_service_principal.github_deploy_sp.object_id
#   role_definition_name = "Contributor"
#   scope                = "/subscriptions/${var.main_subscription_id}"
# }

# Create application for Kobe security audits
resource "azuread_application" "kobe_audit" {
  provider     = azuread
  display_name = "kobe-security-audit"

  lifecycle {
    ignore_changes = [required_resource_access]
  }
}

# Create service principal for the app
resource "azuread_service_principal" "kobe_audit" {
  provider  = azuread
  client_id = azuread_application.kobe_audit.client_id
}

# Create a client secret (password) for authentication
resource "azuread_application_password" "kobe_audit" {
  application_id = azuread_application.kobe_audit.id
  display_name   = "kobe-audit-secret"
  end_date       = "2027-12-31T00:00:00Z"
}

# Assign Reader role across all your subscriptions
resource "azurerm_role_assignment" "kobe_reader_dev" {
  principal_id         = azuread_service_principal.kobe_audit.object_id
  role_definition_name = "Reader"
  scope                = "/subscriptions/${var.dev_subscription_id}"
}

resource "azurerm_role_assignment" "kobe_reader_logging" {
  principal_id         = azuread_service_principal.kobe_audit.object_id
  role_definition_name = "Reader"
  scope                = "/subscriptions/${var.logging_subscription_id}"
}

resource "azurerm_role_assignment" "kobe_reader_firewall" {
  principal_id         = azuread_service_principal.kobe_audit.object_id
  role_definition_name = "Reader"
  scope                = "/subscriptions/${var.firewall_subscription_id}"
}

resource "azurerm_role_assignment" "kobe_reader_identity" {
  principal_id         = azuread_service_principal.kobe_audit.object_id
  role_definition_name = "Reader"
  scope                = "/subscriptions/${var.identity_subscription_id}"
}

resource "azurerm_role_assignment" "kobe_reader_prod" {
  principal_id         = azuread_service_principal.kobe_audit.object_id
  role_definition_name = "Reader"
  scope                = "/subscriptions/${var.prod_subscription_id}"
}
resource "azurerm_role_assignment" "kobe_reader_dashboard" {
  principal_id         = azuread_service_principal.kobe_audit.object_id
  role_definition_name = "Reader"
  scope                = "/subscriptions/${var.dashboard_subscription_id}"
}
resource "azurerm_role_assignment" "kobe_reader_main" {
  principal_id         = azuread_service_principal.kobe_audit.object_id
  role_definition_name = "Reader"
  scope                = "/subscriptions/${var.main_subscription_id}"
}

# Security Reader role for all subscriptions
resource "azurerm_role_assignment" "kobe_security_reader_dev" {
  principal_id         = azuread_service_principal.kobe_audit.object_id
  role_definition_name = "Security Reader"
  scope                = "/subscriptions/${var.dev_subscription_id}"
}

resource "azurerm_role_assignment" "kobe_security_reader_logging" {
  principal_id         = azuread_service_principal.kobe_audit.object_id
  role_definition_name = "Security Reader"
  scope                = "/subscriptions/${var.logging_subscription_id}"
}

resource "azurerm_role_assignment" "kobe_security_reader_firewall" {
  principal_id         = azuread_service_principal.kobe_audit.object_id
  role_definition_name = "Security Reader"
  scope                = "/subscriptions/${var.firewall_subscription_id}"
}

resource "azurerm_role_assignment" "kobe_security_reader_identity" {
  principal_id         = azuread_service_principal.kobe_audit.object_id
  role_definition_name = "Security Reader"
  scope                = "/subscriptions/${var.identity_subscription_id}"
}

resource "azurerm_role_assignment" "kobe_security_reader_prod" {
  principal_id         = azuread_service_principal.kobe_audit.object_id
  role_definition_name = "Security Reader"
  scope                = "/subscriptions/${var.prod_subscription_id}"
}

resource "azurerm_role_assignment" "kobe_security_reader_main" {
  principal_id         = azuread_service_principal.kobe_audit.object_id
  role_definition_name = "Security Reader"
  scope                = "/subscriptions/${var.main_subscription_id}"
}

resource "azurerm_role_assignment" "kobe_security_reader_dashboard" {
  principal_id         = azuread_service_principal.kobe_audit.object_id
  role_definition_name = "Security Reader"
  scope                = "/subscriptions/${var.dashboard_subscription_id}"
}

# Outputs to save
output "kobe_azure_client_id" {
  value       = azuread_application.kobe_audit.client_id
  description = "Kobe service principal client ID"
}

output "kobe_azure_client_secret" {
  value       = azuread_application_password.kobe_audit.value
  description = "Kobe service principal secret"
  sensitive   = true
}

output "kobe_azure_tenant_id" {
  value       = var.tenant_id
  description = "Azure tenant ID"
}

