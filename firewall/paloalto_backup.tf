#checkov:skip=CKV_AZURE_59:Function App requires storage account access; VNet integration provides network isolation
#checkov:skip=CKV_AZURE_206:LRS replication sufficient for scheduled backup function storage
#checkov:skip=CKV_AZURE_114:content_type set on all secrets in module definition
#checkov:skip=CKV_AZURE_212:Min instances not required for timer-triggered backup function
#checkov:skip=CKV_AZURE_225:Zone redundancy not required for scheduled backup function
#checkov:skip=CKV2_AZURE_21:Blob read logging not required for config archive storage
#checkov:skip=CKV2_AZURE_32:Network ACL deny-by-default used; private endpoint not required
#checkov:skip=CKV2_AZURE_33:VNet integration provides isolation; private endpoint not required
#checkov:skip=CKV2_AZURE_41:Connection string auth used for function storage, not SAS tokens
module "palo_alto_backup" {
  source = "../modules/palo-alto-backup-azure"

  providers = {
    azurerm = azurerm.firewall
  }

  resource_group_name = azurerm_resource_group.firewall.name
  location            = var.location
  tenant_id           = var.tenant_id
  subnet_id           = azurerm_subnet.backup_aci.id
  container_image     = var.container_image
  docker_username     = var.docker_username
  docker_password     = var.docker_password

  ses_sender          = var.ses_sender
  ses_recipient       = var.ses_recipient
  deploy_principal_id = data.azuread_service_principal.github_deploy_sp.object_id
  admin_object_ids    = ["6a9b81e7-cd1c-492f-a4ce-fde3081bd4b0"]

  tags = local.required_tags
}

# ---------------------------------------------------------------------------
# RBAC — kobe-security-audit SP (AZURE_CLIENT_ID) needs Storage Blob Data
# Reader on the backup storage account so the ops-automation audit workflow
# can download configs.
# If already assigned manually, import before apply:
#   ASSIGN_ID=$(az role assignment list --assignee <SP_OBJECT_ID> \
#     --role "Storage Blob Data Reader" \
#     --scope <storage_account_id> --query "[0].id" -o tsv)
#   terraform import azurerm_role_assignment.audit_sp_blob_reader "$ASSIGN_ID"
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "audit_sp_blob_reader" {
  provider             = azurerm.firewall
  scope                = module.palo_alto_backup.storage_account_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = data.azuread_service_principal.audit_sp.object_id
}

# ---------------------------------------------------------------------------
# RBAC — kobe-security-audit SP needs Contributor on the backup ACI so the
# ops-automation on-demand backup workflow can stop/start the container to
# trigger an immediate backup run (run_on_startup=true fires on container
# start). Scoped to the container group resource only.
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "audit_sp_aci_contributor" {
  provider             = azurerm.firewall
  scope                = module.palo_alto_backup.container_group_id
  role_definition_name = "Contributor"
  principal_id         = data.azuread_service_principal.audit_sp.object_id
}
