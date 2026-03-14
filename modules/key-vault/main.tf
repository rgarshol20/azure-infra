resource "azurerm_key_vault" "this" {
  name                       = var.name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = var.tenant_id
  sku_name                   = var.sku_name
  soft_delete_retention_days = var.soft_delete_retention_days
  purge_protection_enabled   = var.purge_protection_enabled
  enable_rbac_authorization  = var.enable_rbac_authorization

  # Network isolation (optional)
  dynamic "network_acls" {
    for_each = var.enable_network_acls ? [1] : []
    content {
      bypass                     = var.network_acls_bypass
      default_action             = var.network_acls_default_action
      ip_rules                   = var.network_acls_ip_rules
      virtual_network_subnet_ids = var.network_acls_subnet_ids
    }
  }

  tags = var.tags
}

# Customer-Managed Key for Disk Encryption (optional)
resource "azurerm_key_vault_key" "cmk" {
  #checkov:skip=CKV_AZURE_112:Standard SKU sufficient for CMK; HSM not required for this workload
  #checkov:skip=CKV_AZURE_40:Automated rotation policy configured; manual expiry date not required
  count        = var.create_cmk ? 1 : 0
  name         = var.cmk_key_name
  key_vault_id = azurerm_key_vault.this.id
  key_type     = "RSA"
  key_size     = var.cmk_key_size
  key_opts     = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]

  # HIPAA SEC-03: Automated key rotation policy
  rotation_policy {
    automatic {
      time_before_expiry = "P30D" # Rotate 30 days before expiry
    }
    expire_after         = "P730D" # 2 years (730 days)
    notify_before_expiry = "P30D"  # Notify 30 days before expiry
  }

  depends_on = [azurerm_key_vault.this]
}

# Disk Encryption Set using CMK (optional)
resource "azurerm_disk_encryption_set" "this" {
  count               = var.create_cmk && var.create_des ? 1 : 0
  name                = var.des_name
  location            = var.location
  resource_group_name = var.resource_group_name
  key_vault_key_id    = azurerm_key_vault_key.cmk[0].id

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags

  depends_on = [azurerm_key_vault_key.cmk]
}

# Grant DES access to Key Vault (optional)
resource "azurerm_role_assignment" "des_crypto_user" {
  count                = var.create_cmk && var.create_des ? 1 : 0
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Crypto User"
  principal_id         = azurerm_disk_encryption_set.this[0].identity[0].principal_id

  depends_on = [azurerm_disk_encryption_set.this]
}

resource "azurerm_role_assignment" "des_reader" {
  count                = var.create_cmk && var.create_des ? 1 : 0
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Reader"
  principal_id         = azurerm_disk_encryption_set.this[0].identity[0].principal_id

  depends_on = [azurerm_disk_encryption_set.this]
}

# Additional role assignments for custom principals (optional)
resource "azurerm_role_assignment" "custom" {
  for_each             = var.role_assignments
  scope                = azurerm_key_vault.this.id
  role_definition_name = each.value.role
  principal_id         = each.value.principal_id
}

# Admin password secret (optional)
resource "azurerm_key_vault_secret" "admin_password" {
  #checkov:skip=CKV_AZURE_114:content_type not required for internal admin password secret
  count           = var.create_admin_password ? 1 : 0
  name            = var.admin_password_secret_name
  value           = var.admin_password_value
  key_vault_id    = azurerm_key_vault.this.id
  expiration_date = var.admin_password_expiration_date

  depends_on = [azurerm_key_vault.this, azurerm_role_assignment.custom]
}
