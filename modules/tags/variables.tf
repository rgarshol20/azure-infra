variable "environment" {
  description = "Environment: production, development, or shared"
  type        = string

  validation {
    condition     = contains(["production", "development", "shared"], var.environment)
    error_message = "Environment must be production, development, or shared"
  }
}

variable "owner" {
  description = "Team or individual responsible for the resource"
  type        = string
  default     = "it-security"
}

variable "managed_by" {
  description = "How the resource is managed"
  type        = string
  default     = "terraform"
}

variable "data_classification" {
  description = "Data classification: phi, confidential, internal, or public"
  type        = string

  validation {
    condition     = contains(["phi", "confidential", "internal", "public"], var.data_classification)
    error_message = "Data classification must be phi, confidential, internal, or public"
  }
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "it"
}

variable "compliance_scope" {
  description = "Applicable compliance frameworks (e.g., hipaa-soc2-hitrust)"
  type        = string
}
