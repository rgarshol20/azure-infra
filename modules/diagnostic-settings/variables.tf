variable "diagnostic_setting_name" {
  description = "Name for the diagnostic setting resource"
  type        = string

  validation {
    condition     = length(var.diagnostic_setting_name) > 0 && length(var.diagnostic_setting_name) <= 260
    error_message = "Diagnostic setting name must be between 1 and 260 characters"
  }
}

variable "target_resource_id" {
  description = "Resource ID to attach diagnostic settings to"
  type        = string

  validation {
    condition     = can(regex("^/subscriptions/[a-f0-9-]+(/resourceGroups/|$)", var.target_resource_id))
    error_message = "Target resource ID must be a valid Azure resource ID"
  }
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for operational queries (30-90 day hot window)"
  type        = string

  validation {
    condition     = can(regex("^/subscriptions/[a-f0-9-]+/resourceGroups/.+/providers/Microsoft.OperationalInsights/workspaces/", var.log_analytics_workspace_id))
    error_message = "Log Analytics Workspace ID must be a valid Azure LAW resource ID"
  }
}

variable "storage_account_id" {
  description = "Archive storage account ID for 6-year HIPAA retention with WORM immutability"
  type        = string

  validation {
    condition     = can(regex("^/subscriptions/[a-f0-9-]+/resourceGroups/.+/providers/Microsoft.Storage/storageAccounts/", var.storage_account_id))
    error_message = "Storage account ID must be a valid Azure storage account resource ID"
  }
}

variable "log_categories" {
  description = "List of log categories to enable — varies by resource type. Use 'az monitor diagnostic-settings categories list --resource <id>' to discover valid categories."
  type        = list(string)

  validation {
    condition     = length(var.log_categories) > 0
    error_message = "At least one log category must be specified"
  }
}

variable "metric_categories" {
  description = "List of metric categories to enable. Common: ['AllMetrics']. Set to [] if resource type doesn't support metrics."
  type        = list(string)
  default     = []
}
