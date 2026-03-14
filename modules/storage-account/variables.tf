variable "name" {
  description = "Name of the storage account (3-24 lowercase alphanumeric)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "Storage account name must be 3-24 lowercase alphanumeric characters"
  }
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "account_tier" {
  description = "Storage account tier (Standard or Premium)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "Account tier must be Standard or Premium"
  }
}

variable "account_replication_type" {
  description = "Replication type (LRS, GRS, RAGRS, ZRS)"
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "Invalid replication type"
  }
}

variable "shared_access_key_enabled" {
  description = "Enable shared access keys (disable for HIPAA compliance)"
  type        = bool
  default     = false
}

variable "allow_nested_items_to_be_public" {
  description = "Allow public blob access"
  type        = bool
  default     = false
}

variable "min_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "TLS1_2"
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "network_rules" {
  description = "Network rules configuration"
  type = object({
    default_action = string
    ip_rules       = list(string)
    bypass         = list(string)
  })
  default = null
}

variable "identity_type" {
  description = "Managed identity type (SystemAssigned or UserAssigned)"
  type        = string
  default     = null

  validation {
    condition     = var.identity_type == null || contains(["SystemAssigned", "UserAssigned"], var.identity_type)
    error_message = "Identity type must be SystemAssigned or UserAssigned"
  }
}

variable "identity_ids" {
  description = "List of user-assigned identity IDs (required if identity_type is UserAssigned)"
  type        = list(string)
  default     = null
}

variable "customer_managed_key" {
  description = "Customer-managed encryption key configuration"
  type = object({
    key_vault_key_id          = string
    user_assigned_identity_id = string
  })
  default = null
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
