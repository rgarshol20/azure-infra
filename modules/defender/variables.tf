# Subscription Configuration
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

# Defender for Servers Configuration
variable "enable_defender_for_servers" {
  description = "Enable Defender for Servers"
  type        = bool
  default     = true
}

variable "defender_servers_tier" {
  description = "Defender for Servers tier (Standard or Free)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Free"], var.defender_servers_tier)
    error_message = "Tier must be Standard or Free"
  }
}

variable "defender_servers_subplan" {
  description = "Defender for Servers sub-plan (P1 or P2)"
  type        = string
  default     = "P2"

  validation {
    condition     = contains(["P1", "P2"], var.defender_servers_subplan)
    error_message = "Sub-plan must be P1 or P2"
  }
}

# Defender CSPM Configuration
variable "enable_defender_cspm" {
  description = "Enable Defender Cloud Security Posture Management"
  type        = bool
  default     = true
}

variable "cspm_agentless_vm_scanning_enabled" {
  description = "Enable CSPM AgentlessVmScanning extension"
  type        = bool
  default     = true
}

variable "cspm_agentless_k8s_enabled" {
  description = "Enable CSPM AgentlessDiscoveryForKubernetes extension"
  type        = bool
  default     = true
}

variable "cspm_container_va_enabled" {
  description = "Enable CSPM ContainerRegistriesVulnerabilityAssessments extension"
  type        = bool
  default     = true
}

variable "cspm_entra_permissions_enabled" {
  description = "Enable CSPM EntraPermissionsManagement extension"
  type        = bool
  default     = true
}

variable "cspm_sensitive_data_enabled" {
  description = "Enable CSPM SensitiveDataDiscovery extension"
  type        = bool
  default     = true
}

# MDE Extension Configuration
variable "enable_mde_policies" {
  description = "Enable Microsoft Defender for Endpoint extension policies"
  type        = bool
  default     = true
}

variable "mde_win_policy_definition" {
  description = "MDE Windows policy definition name or ID"
  type        = string
  default     = ""
}

variable "mde_lin_policy_definition" {
  description = "MDE Linux policy definition name or ID"
  type        = string
  default     = ""
}

variable "mde_windows_policy_location" {
  description = "Location for Windows MDE policy assignment"
  type        = string
  default     = "centralus"
}

variable "mde_linux_policy_location" {
  description = "Location for Linux MDE policy assignment"
  type        = string
  default     = "centralus"
}

variable "enable_mde_remediation" {
  description = "Enable MDE policy remediation tasks"
  type        = bool
  default     = true
}

variable "remediation_parallel_deployments" {
  description = "Number of parallel deployments for remediation"
  type        = number
  default     = 10
}

variable "remediation_failure_percentage" {
  description = "Failure percentage threshold for remediation (0.01 to 1.0)"
  type        = number
  default     = 0.10
}

# HIPAA Compliance Configuration
variable "enable_hipaa_policy" {
  description = "Enable HIPAA HITRUST 9.2 policy initiative"
  type        = bool
  default     = false
}

variable "hipaa_policy_set_definition" {
  description = "HIPAA policy set definition name or ID"
  type        = string
  default     = ""
}

variable "hipaa_policy_location" {
  description = "Location for HIPAA policy assignment"
  type        = string
  default     = "centralus"
}

# Security Admin Role
variable "security_admin_principal_ids" {
  description = "List of principal IDs to grant Security Admin role"
  type        = list(string)
  default     = []
}

# Log Analytics Workspace
variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for Defender"
  type        = string
  default     = null
}

# Auto-Remediation
variable "enable_auto_remediation" {
  description = "Enable auto-remediation for security recommendations"
  type        = bool
  default     = false
}

# Tags
variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
