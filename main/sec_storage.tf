# ✅ Create a User-Assigned Managed Identity
resource "azurerm_user_assigned_identity" "storage_identity" {
  name                = "acme-health-main-storage-cmk-identity"
  resource_group_name = azurerm_resource_group.logging.name
  location            = azurerm_resource_group.logging.location

  tags = local.required_tags
}

# ✅ Assign the Managed Identity to the Storage Account
resource "azurerm_storage_account" "encrypted_storage" {
  #checkov:skip=CKV_AZURE_206:SAS tokens disabled (shared_access_key_enabled = false); SAS expiry policy not applicable
  #checkov:skip=CKV_AZURE_33:Queue service not used in this Terraform state storage account
  #checkov:skip=CKV_AZURE_59:Blob logging captured via module diag_storage_blob_main diagnostic settings
  name                     = "acme-health-terraform-state"
  resource_group_name      = azurerm_resource_group.terraform.name
  location                 = azurerm_resource_group.terraform.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  shared_access_key_enabled       = false # <-- prevents Shared Key & SAS
  allow_nested_items_to_be_public = false

  min_tls_version               = "TLS1_2"
  public_network_access_enabled = true

  # Terraform state backend: open network access required for GitHub Actions CI/CD runners.
  # Security enforced via RBAC (shared_access_key_enabled=false, no SAS, CMK encrypted).
  # IP restriction is not appropriate for state storage accessed from dynamic CI runner IPs.
  network_rules {
    #checkov:skip=CKV_AZURE_35:Terraform state backend requires open access for CI/CD runners; secured via RBAC + no SAS + CMK
    default_action = "Allow"
    bypass         = ["AzureServices"] # required so Storage can reach Key Vault for CMK

    private_link_access {
      endpoint_resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Security/datascanners/storageDataScanner"
      endpoint_tenant_id   = data.azurerm_client_config.current.tenant_id
    }
  }

  # ✅ Identity Block (Fixes the Error)
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.storage_identity.id]
  }

  # ✅ Customer-Managed Key Configuration
  customer_managed_key {
    key_vault_key_id          = module.key_vault.cmk_id
    user_assigned_identity_id = azurerm_user_assigned_identity.storage_identity.id
  }

  tags = local.required_tags
}

# Assign required *data-plane* roles on the Storage Account
resource "azurerm_role_assignment" "queue_contrib" {
  scope                = azurerm_storage_account.encrypted_storage.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azuread_service_principal.github_deploy_sp.object_id
}

resource "azurerm_role_assignment" "blob_owner" {
  scope                = azurerm_storage_account.encrypted_storage.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azuread_service_principal.github_deploy_sp.object_id
}

# ✅ Grant Key Vault Permissions to the Managed Identity
resource "azurerm_role_assignment" "storage_key_vault_access" {
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_user_assigned_identity.storage_identity.principal_id
}


resource "azurerm_storage_container" "tfstate" {
  name                  = "terraform-state"
  storage_account_id    = azurerm_storage_account.encrypted_storage.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "installfiles" {
  name                  = "installfiles"
  storage_account_id    = azurerm_storage_account.encrypted_storage.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "configfiles" {
  name                  = "configfiles"
  storage_account_id    = azurerm_storage_account.encrypted_storage.id
  container_access_type = "private"
}

# # Access to the Terraform backend storage account (adjust scope/resource)
# resource "azurerm_role_assignment" "tf_storage_access" {
#   scope                = azurerm_storage_account.encrypted_storage.id
#   role_definition_name = "Storage Blob Data Contributor"
#   principal_id         = data.azuread_service_principal.github_deploy_sp.id

# }