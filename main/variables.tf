variable "location" {
  type        = string
  description = "Azure region"
  default     = "westus"
}

variable "public_key" {
  description = "SSH public key to use for VM login"
  type        = string
}

variable "main_subscription_id" {
  type = string
}
variable "dashboard_subscription_id" {
  type = string
}
variable "logging_subscription_id" {
  type = string
}
variable "firewall_subscription_id" {
  type = string
}
variable "identity_subscription_id" {
  type = string
}
variable "prod_subscription_id" {
  type = string
}
variable "dev_subscription_id" {
  type = string
}
variable "tenant_id" {
  type = string
}
# variable "client_id" {
#   type = string
# }
# variable "client_secret" {
#   type = string
# }
variable "admin_password" {
  type      = string
  sensitive = true
}

variable "admin_ip" {
  type        = string
  description = "IP address of the admin user"
}

variable "cloudpc_ip" {
  description = "Trusted AWS Cloud PC IP/CIDR"
  type        = string
}


variable "hipaa_policy_set_name" {
  description = "The built-in name of the HIPAA HITRUST 9.2 policy set definition"
  type        = string
  default     = "HIPAA-HITRUST-v9.2"
}

variable "hitrust_assessment_name" {
  type = string
}

variable "m365_auth_method" {
  type        = string
  description = "Auth method for microsoft365 provider. Use 'azure_cli' locally, 'oidc_github' in CI."
  default     = "azure_cli"
}