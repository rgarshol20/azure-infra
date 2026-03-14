# =============================================================================
# Microsoft Graph API Permissions for Maester M365 Security Audit
# Add to the same file as azuread_application.kobe_audit
# =============================================================================

# Look up Microsoft Graph's well-known application ID
data "azuread_application_published_app_ids" "well_known" {}

# Get the Microsoft Graph service principal (needed for role IDs and admin consent)
data "azuread_service_principal" "msgraph" {
  client_id = data.azuread_application_published_app_ids.well_known.result["MicrosoftGraph"]
}

# Add Graph API permissions to kobe-security-audit app registration
# All 19 permissions required by Maester — all read-only application permissions
resource "azuread_application_api_access" "kobe_maester_graph" {
  application_id = azuread_application.kobe_audit.id
  api_client_id  = data.azuread_application_published_app_ids.well_known.result["MicrosoftGraph"]

  role_ids = [
    data.azuread_service_principal.msgraph.app_role_ids["DeviceManagementConfiguration.Read.All"],
    data.azuread_service_principal.msgraph.app_role_ids["DeviceManagementManagedDevices.Read.All"],
    data.azuread_service_principal.msgraph.app_role_ids["DeviceManagementRBAC.Read.All"],
    data.azuread_service_principal.msgraph.app_role_ids["Directory.Read.All"],
    data.azuread_service_principal.msgraph.app_role_ids["DirectoryRecommendations.Read.All"],
    data.azuread_service_principal.msgraph.app_role_ids["IdentityRiskEvent.Read.All"],
    data.azuread_service_principal.msgraph.app_role_ids["Policy.Read.All"],
    data.azuread_service_principal.msgraph.app_role_ids["Policy.Read.ConditionalAccess"],
    data.azuread_service_principal.msgraph.app_role_ids["PrivilegedAccess.Read.AzureAD"],
    data.azuread_service_principal.msgraph.app_role_ids["Reports.Read.All"],
    data.azuread_service_principal.msgraph.app_role_ids["ReportSettings.Read.All"],
    data.azuread_service_principal.msgraph.app_role_ids["RoleEligibilitySchedule.Read.Directory"],
    data.azuread_service_principal.msgraph.app_role_ids["RoleManagement.Read.All"],
    data.azuread_service_principal.msgraph.app_role_ids["SecurityIdentitiesSensors.Read.All"],
    data.azuread_service_principal.msgraph.app_role_ids["SecurityIdentitiesHealth.Read.All"],
    data.azuread_service_principal.msgraph.app_role_ids["SharePointTenantSettings.Read.All"],
    data.azuread_service_principal.msgraph.app_role_ids["ThreatHunting.Read.All"],
    data.azuread_service_principal.msgraph.app_role_ids["UserAuthenticationMethod.Read.All"],
    data.azuread_service_principal.msgraph.app_role_ids["OnPremDirectorySynchronization.Read.All"],
    # Required for Get-MgUser -Property SignInActivity (last sign-in for stale account detection)
    data.azuread_service_principal.msgraph.app_role_ids["AuditLog.Read.All"],
    # Required by intune-audit.ps1: BitLocker recovery key escrow status (metadata only, not actual keys)
    data.azuread_service_principal.msgraph.app_role_ids["BitlockerKey.ReadBasic.All"],
    # Required by intune-audit.ps1: stale device owner profile enrichment (displayName, department, jobTitle)
    # Note: technically covered by Directory.Read.All already granted above, but added here for explicit intent
    data.azuread_service_principal.msgraph.app_role_ids["User.Read.All"],
  ]
}

# Grant admin consent for each permission
# This is the Terraform equivalent of clicking "Grant admin consent" in the portal
# Each azuread_app_role_assignment grants consent for one permission

locals {
  maester_graph_permissions = [
    "DeviceManagementConfiguration.Read.All",
    "DeviceManagementManagedDevices.Read.All",
    "DeviceManagementRBAC.Read.All",
    "Directory.Read.All",
    "DirectoryRecommendations.Read.All",
    "IdentityRiskEvent.Read.All",
    "Policy.Read.All",
    "Policy.Read.ConditionalAccess",
    "PrivilegedAccess.Read.AzureAD",
    "Reports.Read.All",
    "ReportSettings.Read.All",
    "RoleEligibilitySchedule.Read.Directory",
    "RoleManagement.Read.All",
    "SecurityIdentitiesSensors.Read.All",
    "SecurityIdentitiesHealth.Read.All",
    "SharePointTenantSettings.Read.All",
    "ThreatHunting.Read.All",
    "UserAuthenticationMethod.Read.All",
    "OnPremDirectorySynchronization.Read.All",
    "AuditLog.Read.All",
    # Required by intune-audit.ps1 — BitLocker key escrow status (key metadata only, not actual keys)
    "BitlockerKey.ReadBasic.All",
    # Required by intune-audit.ps1 — stale device owner enrichment (covered by Directory.Read.All but explicit)
    "User.Read.All",
  ]
}

resource "azuread_app_role_assignment" "kobe_maester_consent" {
  for_each = toset(local.maester_graph_permissions)

  app_role_id         = data.azuread_service_principal.msgraph.app_role_ids[each.value]
  principal_object_id = azuread_service_principal.kobe_audit.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

# Federated credential for Maester workflow in ops-automation
# Only needed if kobe-security-audit doesn't already have one for ops-automation
# Check: Entra > App registrations > kobe-security-audit > Certificates & secrets > Federated credentials
# If it already exists, remove this block and import won't be needed
# =============================================================================
# Exchange Online — Exchange.ManageAsApp permission
# Required for Maester Exchange Online security tests (include_exchange: true)
# =============================================================================

# Look up Office 365 Exchange Online service principal (separate from Microsoft Graph)
data "azuread_service_principal" "exchange_online" {
  client_id = "00000002-0000-0ff1-ce00-000000000000" # Well-known Exchange Online app ID
}

# Add Exchange.ManageAsApp application permission to kobe-security-audit
resource "azuread_application_api_access" "kobe_maester_exchange" {
  application_id = azuread_application.kobe_audit.id
  api_client_id  = "00000002-0000-0ff1-ce00-000000000000"

  role_ids = [
    data.azuread_service_principal.exchange_online.app_role_ids["Exchange.ManageAsApp"],
  ]
}

# Grant admin consent for Exchange.ManageAsApp
resource "azuread_app_role_assignment" "kobe_maester_exchange_consent" {
  app_role_id         = data.azuread_service_principal.exchange_online.app_role_ids["Exchange.ManageAsApp"]
  principal_object_id = azuread_service_principal.kobe_audit.object_id
  resource_object_id  = data.azuread_service_principal.exchange_online.object_id
}

# =============================================================================
# Teams — Teams Reader directory role
# Required for Maester Teams security tests (include_teams: true)
# Uses azuread_directory_role to auto-activate the role if not yet active
# =============================================================================

resource "azuread_directory_role" "teams_reader" {
  display_name = "Teams Reader"
}

resource "azuread_directory_role_assignment" "kobe_teams_reader" {
  role_id             = azuread_directory_role.teams_reader.template_id
  principal_object_id = azuread_service_principal.kobe_audit.object_id
}

# =============================================================================
# Federated credential
# =============================================================================

resource "azuread_application_federated_identity_credential" "kobe_oidc_ops_automation" {
  application_id = azuread_application.kobe_audit.id
  display_name   = "ops-automation-main"
  description    = "Federated identity for Maester and HIPAA audit workflows"
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:AcmeHealthInc/ops-automation:ref:refs/heads/main"
  audiences      = ["api://AzureADTokenExchange"]
}
