# =============================================================================
# App Registration — Device Management Reader
#
# Purpose: Provides read access to Intune managed device data via Microsoft
# Graph API. Used by external tools/integrations that need device inventory.
#
# TODO: Update display_name to match the specific tool/vendor (e.g.,
#       "splunk-intune-reader", "servicenow-mdm-reader", etc.)
#
# Permissions granted:
#   - DeviceManagementManagedDevices.Read.All (Delegated)
#   - DeviceManagementManagedDevices.Read.All (Application)
#
# Dependencies: data.azuread_application_published_app_ids.well_known and
# data.azuread_service_principal.msgraph are declared in
# maester-graph-permissions.tf and reused here.
# =============================================================================

resource "azuread_application" "device_mgmt_reader" {
  provider     = azuread
  display_name = "device-mgmt-reader"
}

resource "azuread_service_principal" "device_mgmt_reader" {
  provider  = azuread
  client_id = azuread_application.device_mgmt_reader.client_id
}

resource "azuread_application_password" "device_mgmt_reader" {
  application_id = azuread_application.device_mgmt_reader.id
  display_name   = "device-mgmt-reader-secret"
  end_date       = "2027-12-31T00:00:00Z"
}

# API permissions — both delegated (scope_ids) and application (role_ids)
resource "azuread_application_api_access" "device_mgmt_reader_graph" {
  application_id = azuread_application.device_mgmt_reader.id
  api_client_id  = data.azuread_application_published_app_ids.well_known.result["MicrosoftGraph"]

  scope_ids = [
    data.azuread_service_principal.msgraph.oauth2_permission_scope_ids["DeviceManagementManagedDevices.Read.All"],
  ]

  role_ids = [
    data.azuread_service_principal.msgraph.app_role_ids["DeviceManagementManagedDevices.Read.All"],
  ]
}

# Admin consent for application permission
resource "azuread_app_role_assignment" "device_mgmt_reader_app_consent" {
  app_role_id         = data.azuread_service_principal.msgraph.app_role_ids["DeviceManagementManagedDevices.Read.All"]
  principal_object_id = azuread_service_principal.device_mgmt_reader.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

# Admin consent for delegated permission (grants on behalf of all users in tenant)
resource "azuread_service_principal_delegated_permission_grant" "device_mgmt_reader_delegated_consent" {
  service_principal_object_id          = azuread_service_principal.device_mgmt_reader.object_id
  resource_service_principal_object_id = data.azuread_service_principal.msgraph.object_id
  claim_values                         = ["DeviceManagementManagedDevices.Read.All"]
}

# =============================================================================
# Outputs — client ID, tenant ID, and secret for use in the target tool
# =============================================================================

output "device_mgmt_reader_client_id" {
  value       = azuread_application.device_mgmt_reader.client_id
  description = "Application (client) ID — enter this in your tool's configuration"
}

output "device_mgmt_reader_tenant_id" {
  value       = var.tenant_id
  description = "Directory (tenant) ID"
}

output "device_mgmt_reader_client_secret" {
  value       = azuread_application_password.device_mgmt_reader.value
  description = "Client secret value — store this immediately, not retrievable again"
  sensitive   = true
}
