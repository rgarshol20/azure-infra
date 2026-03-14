variable "state_resource_group" {
  description = "Resource group containing the terraform state storage account"
  type        = string
  default     = "rg-main-terraform"
}

variable "state_storage_account" {
  description = "Storage account name for terraform state"
  type        = string
  default     = "acme-health-terraform-state"
}

variable "state_container" {
  description = "Container name for terraform state"
  type        = string
  default     = "terraform-state"
}

variable "use_azuread_auth" {
  description = "Use Azure AD authentication for state backend"
  type        = bool
  default     = true
}

variable "use_oidc" {
  description = "Use OIDC authentication for state backend (CI/CD only)"
  type        = bool
  default     = true
}
