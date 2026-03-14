variable "storage_account_name" {
  description = "Storage account name for HIPAA log archive (3-24 lowercase alphanumeric, no hyphens)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account name must be 3-24 lowercase alphanumeric characters (no hyphens)"
  }
}

variable "resource_group_name" {
  description = "Resource group name for log archive storage account"
  type        = string
}

variable "location" {
  description = "Azure region for log archive resources (e.g., eastus, westus2)"
  type        = string
}

variable "tags" {
  description = "Required tags (must include: environment, owner, managed-by, data-classification, cost-center, compliance-scope)"
  type        = map(string)

  validation {
    condition = alltrue([
      contains(keys(var.tags), "environment"),
      contains(keys(var.tags), "owner"),
      contains(keys(var.tags), "managed-by"),
      contains(keys(var.tags), "data-classification"),
      contains(keys(var.tags), "cost-center"),
      contains(keys(var.tags), "compliance-scope")
    ])
    error_message = "Tags must include all 6 required keys: environment, owner, managed-by, data-classification, cost-center, compliance-scope"
  }
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for dual-destination logging (hot querying alongside archive storage)"
  type        = string
}

variable "nsg_ids" {
  description = "Map of NSG names to NSG IDs for flow log enablement (e.g., {\"main-nsg\" = \"/subscriptions/.../networkSecurityGroups/main-nsg\"})"
  type        = map(string)
  default     = {}
}

variable "vm_ids" {
  description = "List of VM resource IDs for Windows Event Log collection via Data Collection Rule"
  type        = list(string)
  default     = []
}

variable "network_watcher_name" {
  description = "Name of existing Network Watcher resource (typically NetworkWatcher_<region>)"
  type        = string
}

variable "network_watcher_rg" {
  description = "Resource group containing the Network Watcher resource (typically NetworkWatcherRG)"
  type        = string
}

variable "entra_diagnostic_setting_name" {
  description = "Name for Entra ID diagnostic setting resource"
  type        = string
  default     = "entra-archive-diag"
}

variable "activity_diagnostic_setting_name" {
  description = "Name for Activity Log diagnostic setting resource"
  type        = string
  default     = "activity-archive-diag"
}

variable "dcr_name" {
  description = "Name for Data Collection Rule resource"
  type        = string
  default     = "windows-archive-dcr"
}

variable "admin_ip" {
  description = "Admin IP address for network ACL whitelisting"
  type        = string
}

variable "cloudpc_ip" {
  description = "Cloud PC IP address for network ACL whitelisting"
  type        = string
}
