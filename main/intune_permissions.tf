# =============================================================================
# Microsoft Graph API Permissions for GitHub Deploy SP — Intune Management
#
# Grants the two application permissions required by the microsoft365 Terraform
# provider to read and write Intune compliance policies.
#
# data.azuread_application_published_app_ids.well_known and
# data.azuread_service_principal.msgraph are declared in
# maester-graph-permissions.tf and reused here.
# =============================================================================

resource "azuread_app_role_assignment" "deploy_sp_device_mgmt_rw" {
  app_role_id         = data.azuread_service_principal.msgraph.app_role_ids["DeviceManagementConfiguration.ReadWrite.All"]
  principal_object_id = azuread_service_principal.github_deploy_sp.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

resource "azuread_app_role_assignment" "deploy_sp_directory_read" {
  app_role_id         = data.azuread_service_principal.msgraph.app_role_ids["Directory.Read.All"]
  principal_object_id = azuread_service_principal.github_deploy_sp.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

# Required for Terraform to create and manage Azure AD app registrations
resource "azuread_app_role_assignment" "deploy_sp_app_rw_all" {
  app_role_id         = data.azuread_service_principal.msgraph.app_role_ids["Application.ReadWrite.All"]
  principal_object_id = azuread_service_principal.github_deploy_sp.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

# Required to grant Graph API permissions (app role assignments) to new service principals
resource "azuread_app_role_assignment" "deploy_sp_approle_rw_all" {
  app_role_id         = data.azuread_service_principal.msgraph.app_role_ids["AppRoleAssignment.ReadWrite.All"]
  principal_object_id = azuread_service_principal.github_deploy_sp.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

# Required to create delegated permission grants for new service principals
resource "azuread_app_role_assignment" "deploy_sp_delegated_grant_rw_all" {
  app_role_id         = data.azuread_service_principal.msgraph.app_role_ids["DelegatedPermissionGrant.ReadWrite.All"]
  principal_object_id = azuread_service_principal.github_deploy_sp.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}
