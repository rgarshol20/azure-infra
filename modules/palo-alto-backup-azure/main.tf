terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0, < 5.0"
    }
  }
}

locals {
  prefix = "palo-alto-backup"
}

# ---------------------------------------------------------------------------
# Storage Account — config archive and hash state
# ---------------------------------------------------------------------------

resource "azurerm_storage_account" "backup" {
  #checkov:skip=CKV_AZURE_33:Queue logging not required for function app storage
  #checkov:skip=CKV_AZURE_59:Public blob access disabled via allow_nested_items_to_be_public = false; VNet integration provides network isolation
  #checkov:skip=CKV_AZURE_206:LRS replication sufficient for scheduled backup function storage
  #checkov:skip=CKV2_AZURE_1:CMK not required for backup function storage in this environment
  #checkov:skip=CKV2_AZURE_38:Soft delete not required for hash state blobs
  #checkov:skip=CKV2_AZURE_40:Table logging not required for function app storage
  name                            = replace("${local.prefix}sa", "-", "")
  location                        = var.location
  resource_group_name             = var.resource_group_name
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  https_traffic_only_enabled      = true

  tags = merge(var.tags, {
    Name      = replace("${local.prefix}sa", "-", "")
    Component = "palo-alto-backup"
  })
}

resource "azurerm_storage_container" "backup" {
  name                  = var.backup_container
  storage_account_id    = azurerm_storage_account.backup.id
  container_access_type = "private"
}

resource "azurerm_storage_management_policy" "backup" {
  storage_account_id = azurerm_storage_account.backup.id

  rule {
    name    = "archive-configs"
    enabled = true

    filters {
      prefix_match = ["${var.backup_container}/archive/"]
      blob_types   = ["blockBlob"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = 90
        tier_to_archive_after_days_since_modification_greater_than = 365
        delete_after_days_since_modification_greater_than          = 2190 # 6 years — HIPAA
      }
    }
  }

  rule {
    name    = "expire-hash-versions"
    enabled = true

    filters {
      prefix_match = ["${var.backup_container}/hashes/"]
      blob_types   = ["blockBlob"]
    }

    actions {
      snapshot {
        delete_after_days_since_creation_greater_than = 30
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Key Vault — secrets for device credentials, GitHub PAT, SES SMTP
# ---------------------------------------------------------------------------

resource "azurerm_key_vault" "backup" {
  #checkov:skip=CKV_AZURE_109:KV allows public access for ephemeral runner IPs; access controlled strictly by access policies (function MI + deploy SP only)
  #checkov:skip=CKV_AZURE_189:KV allows public network access; ephemeral runner IPs cannot be pre-allowlisted; access controlled by strict access policies
  #checkov:skip=CKV2_AZURE_32:Network ACL removed — plan/apply run on ephemeral runners with rotating IPs; KV secured by strict access policies (function MI + deploy SP only)
  name                       = "${local.prefix}-kv"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 90
  purge_protection_enabled   = true

  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow"
  }

  tags = merge(var.tags, {
    Name      = "${local.prefix}-kv"
    Component = "palo-alto-backup"
  })
}

# Grant deploy service principal access to manage secrets during Terraform runs
resource "azurerm_key_vault_access_policy" "deploy_sp" {
  count        = var.deploy_principal_id != "" ? 1 : 0
  key_vault_id = azurerm_key_vault.backup.id
  tenant_id    = var.tenant_id
  object_id    = var.deploy_principal_id

  secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
}

# Grant admin users access to manage secrets manually
resource "azurerm_key_vault_access_policy" "admin_users" {
  for_each     = toset(var.admin_object_ids)
  key_vault_id = azurerm_key_vault.backup.id
  tenant_id    = var.tenant_id
  object_id    = each.value

  secret_permissions = ["Get", "List", "Set", "Delete"]
}

# Grant container group managed identity access to read secrets
resource "azurerm_key_vault_access_policy" "container" {
  key_vault_id = azurerm_key_vault.backup.id
  tenant_id    = var.tenant_id
  object_id    = azurerm_container_group.backup.identity[0].principal_id

  secret_permissions = ["Get", "List"]

  depends_on = [azurerm_container_group.backup]
}

# ---------------------------------------------------------------------------
# Key Vault Secrets — placeholder values; populate post-deploy via az keyvault
# ---------------------------------------------------------------------------

resource "azurerm_key_vault_secret" "github_token" {
  #checkov:skip=CKV_AZURE_41:Secret rotation managed externally; expiry not set for PAT placeholder
  #checkov:skip=CKV_AZURE_114:content_type not required for JSON-encoded bootstrap placeholder secrets
  name         = var.github_secret_name
  value        = jsonencode({ token = "REPLACE_ME", repo = "REPLACE_ME", branch = "main" })
  key_vault_id = azurerm_key_vault.backup.id

  lifecycle {
    ignore_changes = [value]
  }

  tags = merge(var.tags, { Component = "palo-alto-backup" })
}

resource "azurerm_key_vault_secret" "ses_smtp" {
  #checkov:skip=CKV_AZURE_41:Secret rotation managed externally
  #checkov:skip=CKV_AZURE_114:content_type not required for JSON-encoded bootstrap placeholder secrets
  name         = var.ses_smtp_secret_name
  value        = jsonencode({ username = "REPLACE_ME", password = "REPLACE_ME" })
  key_vault_id = azurerm_key_vault.backup.id

  lifecycle {
    ignore_changes = [value]
  }

  tags = merge(var.tags, { Component = "palo-alto-backup" })
}

resource "azurerm_key_vault_secret" "panorama" {
  #checkov:skip=CKV_AZURE_41:Secret rotation managed externally
  #checkov:skip=CKV_AZURE_114:content_type not required for JSON-encoded bootstrap placeholder secrets
  name         = "palo-alto-backup-azure-prod-panorama"
  value        = jsonencode({ ip = "REPLACE_ME", api_key = "REPLACE_ME" })
  key_vault_id = azurerm_key_vault.backup.id

  lifecycle {
    ignore_changes = [value]
  }

  tags = merge(var.tags, { Component = "palo-alto-backup" })
}

resource "azurerm_key_vault_secret" "firewall" {
  #checkov:skip=CKV_AZURE_41:Secret rotation managed externally
  #checkov:skip=CKV_AZURE_114:content_type not required for JSON-encoded bootstrap placeholder secrets
  name         = "palo-alto-backup-azure-prod-firewall"
  value        = jsonencode({ ip = "REPLACE_ME", api_key = "REPLACE_ME" })
  key_vault_id = azurerm_key_vault.backup.id

  lifecycle {
    ignore_changes = [value]
  }

  tags = merge(var.tags, { Component = "palo-alto-backup" })
}

# ---------------------------------------------------------------------------
# Container Group — Azure Functions Python runtime in ACI
# Timer trigger (backup: daily 02:30 UTC) is handled natively by the
# Functions host inside the container.
# Audit is handled by the ops-automation GitHub Actions workflow.
# ---------------------------------------------------------------------------

resource "azurerm_container_group" "backup" {
  #checkov:skip=CKV_AZURE_98:Container group deployed into VNet via subnet_ids
  #checkov:skip=CKV_AZURE_235:Storage connection string in env var is infrastructure config; all device credentials are fetched from Key Vault at runtime
  #checkov:skip=CKV_AZURE_245:Container group deployed into VNet via subnet_ids
  name                = "${local.prefix}-aci"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  restart_policy      = "Always"
  ip_address_type     = "Private"
  subnet_ids          = [var.subnet_id]

  identity {
    type = "SystemAssigned"
  }

  container {
    name   = "palo-alto-backup"
    image  = var.container_image
    cpu    = "0.25"
    memory = "0.5"

    ports {
      port     = 80
      protocol = "TCP"
    }

    environment_variables = {
      FUNCTIONS_WORKER_RUNTIME = "python"
      AzureWebJobsStorage      = azurerm_storage_account.backup.primary_connection_string
      DEPLOYMENT_NAME          = var.deployment_name
      DEVICES                  = jsonencode(var.devices)
      BACKUP_CONTAINER         = var.backup_container
      KEYVAULT_URI             = azurerm_key_vault.backup.vault_uri
      GITHUB_SECRET_NAME       = var.github_secret_name
      SES_SMTP_SECRET_NAME     = var.ses_smtp_secret_name
      SES_SENDER               = var.ses_sender
      SES_RECIPIENT            = var.ses_recipient
      SES_SMTP_HOST            = var.ses_smtp_host
      BACKUP_STORAGE_CONN_STR  = azurerm_storage_account.backup.primary_connection_string
    }
  }

  dynamic "image_registry_credential" {
    for_each = var.docker_username != "" ? [1] : []
    content {
      server   = "index.docker.io"
      username = var.docker_username
      password = var.docker_password
    }
  }

  tags = merge(var.tags, {
    Name      = "${local.prefix}-aci"
    Component = "palo-alto-backup"
  })

  depends_on = [azurerm_storage_account.backup]
}

