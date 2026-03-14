# =============================================================================
# Microsoft Defender for Endpoint (MDE) API Permissions — github-deploy-app
#
# Required by intune-vuln-audit.py in ops-automation to pull endpoint
# vulnerability findings from the MDE Security Center API.
#
# API: WindowsDefenderATP (fc780465-2017-40d4-a0c5-307022471b92)
#   Separate from Microsoft Graph — requires its own service principal lookup.
#
# Permissions granted (application):
#   - Machine.Read.All       — enumerate enrolled devices
#   - Vulnerability.Read.All — read TVM vulnerability findings per device
# =============================================================================

# Look up the Windows Defender ATP service principal (MDE Security Center API)
data "azuread_service_principal" "windows_defender_atp" {
  client_id = "fc780465-2017-40d4-a0c5-307022471b92"
}

# Declare the MDE API permissions on the github-deploy-app registration
resource "azuread_application_api_access" "github_deploy_mde" {
  application_id = azuread_application.github_deploy_app.id
  api_client_id  = "fc780465-2017-40d4-a0c5-307022471b92"

  role_ids = [
    data.azuread_service_principal.windows_defender_atp.app_role_ids["Machine.Read.All"],
    data.azuread_service_principal.windows_defender_atp.app_role_ids["Vulnerability.Read.All"],
  ]
}

# Grant admin consent for Machine.Read.All
resource "azuread_app_role_assignment" "github_deploy_mde_machine_read" {
  app_role_id         = data.azuread_service_principal.windows_defender_atp.app_role_ids["Machine.Read.All"]
  principal_object_id = azuread_service_principal.github_deploy_sp.object_id
  resource_object_id  = data.azuread_service_principal.windows_defender_atp.object_id
}

# Grant admin consent for Vulnerability.Read.All
resource "azuread_app_role_assignment" "github_deploy_mde_vuln_read" {
  app_role_id         = data.azuread_service_principal.windows_defender_atp.app_role_ids["Vulnerability.Read.All"]
  principal_object_id = azuread_service_principal.github_deploy_sp.object_id
  resource_object_id  = data.azuread_service_principal.windows_defender_atp.object_id
}

# =============================================================================
# Same MDE permissions on kobe-security-audit
# AZURE_CLIENT_ID in ops-automation may point to either app — cover both.
# =============================================================================

resource "azuread_application_api_access" "kobe_audit_mde" {
  application_id = azuread_application.kobe_audit.id
  api_client_id  = "fc780465-2017-40d4-a0c5-307022471b92"

  role_ids = [
    data.azuread_service_principal.windows_defender_atp.app_role_ids["Machine.Read.All"],
    data.azuread_service_principal.windows_defender_atp.app_role_ids["Vulnerability.Read.All"],
  ]
}

resource "azuread_app_role_assignment" "kobe_audit_mde_machine_read" {
  app_role_id         = data.azuread_service_principal.windows_defender_atp.app_role_ids["Machine.Read.All"]
  principal_object_id = azuread_service_principal.kobe_audit.object_id
  resource_object_id  = data.azuread_service_principal.windows_defender_atp.object_id
}

resource "azuread_app_role_assignment" "kobe_audit_mde_vuln_read" {
  app_role_id         = data.azuread_service_principal.windows_defender_atp.app_role_ids["Vulnerability.Read.All"]
  principal_object_id = azuread_service_principal.kobe_audit.object_id
  resource_object_id  = data.azuread_service_principal.windows_defender_atp.object_id
}
