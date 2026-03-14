variable "name" {
  description = "Key vault name (3-24 alphanumeric and hyphens)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,22}[a-zA-Z0-9]$", var.name))
    error_message = "Key vault name must be 3-24 characters, start with letter, alphanumeric and hyphens only"
  }
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "sku_name" {
  description = "SKU name (standard or premium)"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "SKU must be standard or premium"
  }
}

variable "soft_delete_retention_days" {
  description = "Soft delete retention in days (7-90)"
  type        = number
  default     = 90

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Retention must be between 7 and 90 days"
  }
}

variable "purge_protection_enabled" {
  description = "Enable purge protection (recommended for HIPAA)"
  type        = bool
  default     = true
}

variable "enable_rbac_authorization" {
  description = "Use RBAC for access control (recommended over access policies)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}

# Network ACLs Configuration
variable "enable_network_acls" {
  description = "Enable network ACLs for the key vault"
  type        = bool
  default     = false
}

variable "network_acls_bypass" {
  description = "Network ACL bypass (e.g., AzureServices)"
  type        = string
  default     = "AzureServices"
}

variable "network_acls_default_action" {
  description = "Default network ACL action (Allow or Deny)"
  type        = string
  default     = "Deny"
}

variable "network_acls_ip_rules" {
  description = "List of IP addresses or CIDR blocks to allow"
  type        = list(string)
  default     = []
}

variable "network_acls_subnet_ids" {
  description = "List of subnet IDs to allow"
  type        = list(string)
  default     = []
}

# Customer-Managed Key Configuration
variable "create_cmk" {
  description = "Create a customer-managed key for disk encryption"
  type        = bool
  default     = false
}

variable "cmk_key_name" {
  description = "Name for the CMK key"
  type        = string
  default     = "disk-encryption-key"
}

variable "cmk_key_size" {
  description = "CMK key size (2048, 3072, or 4096)"
  type        = number
  default     = 4096

  validation {
    condition     = contains([2048, 3072, 4096], var.cmk_key_size)
    error_message = "Key size must be 2048, 3072, or 4096"
  }
}

# Disk Encryption Set Configuration
variable "create_des" {
  description = "Create a Disk Encryption Set using the CMK"
  type        = bool
  default     = false
}

variable "des_name" {
  description = "Name for the Disk Encryption Set"
  type        = string
  default     = "disk-encryption-set"
}

# Role Assignments
variable "role_assignments" {
  description = "Map of role assignments for the key vault"
  type = map(object({
    role         = string
    principal_id = string
  }))
  default = {}
}

# Admin Password Secret
variable "create_admin_password" {
  description = "Create an admin password secret in the vault"
  type        = bool
  default     = false
}

variable "admin_password_secret_name" {
  description = "Name for the admin password secret"
  type        = string
  default     = "admin-password"
}

variable "admin_password_value" {
  description = "Value for the admin password secret"
  type        = string
  default     = ""
  sensitive   = true
}

variable "admin_password_expiration_date" {
  description = "Expiration date for the admin password secret (RFC3339, e.g. 2028-03-05T00:00:00Z)"
  type        = string
  default     = null
}
