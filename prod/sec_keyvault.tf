# Key Vault - Module Adoption
module "key_vault" {
  source    = "../modules/key-vault"
  providers = { azurerm = azurerm.prod }

  name                           = "prod-dde-key-vault"
  location                       = azurerm_resource_group.logging.location
  resource_group_name            = azurerm_resource_group.logging.name
  tenant_id                      = var.tenant_id
  enable_network_acls            = true
  network_acls_bypass            = "AzureServices"
  network_acls_default_action    = "Deny"
  network_acls_ip_rules          = [var.admin_ip, var.cloudpc_ip]
  create_cmk                     = true
  cmk_key_name                   = "acme-health-prod-cmk-key"
  cmk_key_size                   = 2048
  create_des                     = true
  des_name                       = "acme-health-prod-hipaa-disk-encryption-set"
  create_admin_password          = true
  admin_password_secret_name     = "admin-password"
  admin_password_value           = var.admin_password
  admin_password_expiration_date = "2028-03-05T00:00:00Z"
  tags = merge(local.required_tags, {
    Name = "acme-health-prod-key-vault"
  })
}
