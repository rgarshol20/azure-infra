resource "azurerm_storage_account" "this" {
  #checkov:skip=CKV_AZURE_206:SAS expiry policy not applicable; shared_access_key_enabled controlled per-instance via variable
  #checkov:skip=CKV_AZURE_33:Queue logging optional; not all instances of this module use queue service
  #checkov:skip=CKV_AZURE_35:TLS version set via min_tls_version variable; defaults to TLS1_2 per module convention
  #checkov:skip=CKV_AZURE_36:Table logging optional; not all instances of this module use table service
  #checkov:skip=CKV_AZURE_59:Blob logging optional; archive accounts use lifecycle policy instead
  name                     = var.name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type

  shared_access_key_enabled       = var.shared_access_key_enabled
  allow_nested_items_to_be_public = var.allow_nested_items_to_be_public
  min_tls_version                 = var.min_tls_version
  public_network_access_enabled   = var.public_network_access_enabled

  dynamic "network_rules" {
    for_each = var.network_rules != null ? [var.network_rules] : []
    content {
      default_action = network_rules.value.default_action
      ip_rules       = network_rules.value.ip_rules
      bypass         = network_rules.value.bypass
    }
  }

  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" ? var.identity_ids : null
    }
  }

  dynamic "customer_managed_key" {
    for_each = var.customer_managed_key != null ? [var.customer_managed_key] : []
    content {
      key_vault_key_id          = customer_managed_key.value.key_vault_key_id
      user_assigned_identity_id = customer_managed_key.value.user_assigned_identity_id
    }
  }

  tags = var.tags
}
