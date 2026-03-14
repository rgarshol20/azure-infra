variable "vault_name" {
  description = "Recovery Services Vault name (follows naming: rsv-<env>-<region>)"
  type        = string
  validation {
    condition     = can(regex("^rsv-[a-z]+-[a-z0-9]+$", var.vault_name))
    error_message = "Vault name must follow format: rsv-<env>-<region>."
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

variable "sku" {
  description = "Vault SKU"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Standard", "RS0"], var.sku)
    error_message = "SKU must be 'Standard' or 'RS0'."
  }
}

variable "soft_delete_enabled" {
  description = "Enable soft delete (14-day retention for ransomware protection)"
  type        = bool
  default     = true
}

variable "immutability" {
  description = "Immutability setting: Disabled, Unlocked, or Locked. Unlocked prevents disabling soft delete but can be upgraded to Locked later."
  type        = string
  default     = "Unlocked"
  validation {
    condition     = contains(["Disabled", "Unlocked", "Locked"], var.immutability)
    error_message = "Immutability must be 'Disabled', 'Unlocked', or 'Locked'."
  }
}

variable "cross_region_restore_enabled" {
  description = "Enable cross-region restore"
  type        = bool
  default     = false
}

variable "vm_backup_policies" {
  description = "List of VM backup policy configurations"
  type = list(object({
    name                           = string
    backup_frequency               = string
    backup_time                    = string
    retention_daily_count          = number
    policy_type                    = optional(string)
    instant_restore_retention_days = optional(number)
    retention_weekly_count         = optional(number)
    retention_weekly_weekdays      = optional(list(string))
    retention_monthly_count        = optional(number)
    retention_monthly_weekdays     = optional(list(string))
    retention_monthly_weeks        = optional(list(string))
    retention_yearly_count         = optional(number)
    retention_yearly_months        = optional(list(string))
    retention_yearly_weekdays      = optional(list(string))
    retention_yearly_weeks         = optional(list(string))
    timezone                       = optional(string)
  }))
  default = []
}

variable "sql_backup_policies" {
  description = "List of SQL backup policy configurations"
  type = list(object({
    name                         = string
    full_backup_frequency        = optional(string)
    full_backup_time             = optional(string)
    log_backup_enabled           = optional(bool)
    log_backup_frequency_minutes = optional(number)
    log_retention_days           = optional(number)
    retention_daily_count        = optional(number)
    retention_weekly_count       = optional(number)
    retention_weekly_weekdays    = optional(list(string))
    retention_monthly_count      = optional(number)
    retention_monthly_weekdays   = optional(list(string))
    retention_monthly_weeks      = optional(list(string))
    retention_yearly_count       = optional(number)
    retention_yearly_months      = optional(list(string))
    retention_yearly_weekdays    = optional(list(string))
    retention_yearly_weeks       = optional(list(string))
    timezone                     = optional(string)
    compression_enabled          = optional(bool)
  }))
  default = []
}

variable "file_share_backup_policies" {
  description = "List of file share backup policy configurations"
  type = list(object({
    name                       = string
    backup_frequency           = optional(string)
    backup_time                = optional(string)
    retention_daily_count      = optional(number)
    retention_weekly_count     = optional(number)
    retention_weekly_weekdays  = optional(list(string))
    retention_monthly_count    = optional(number)
    retention_monthly_weekdays = optional(list(string))
    retention_monthly_weeks    = optional(list(string))
    retention_yearly_count     = optional(number)
    retention_yearly_months    = optional(list(string))
    retention_yearly_weekdays  = optional(list(string))
    retention_yearly_weeks     = optional(list(string))
    timezone                   = optional(string)
  }))
  default = []
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
