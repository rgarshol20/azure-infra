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

variable "docker_username" {
  description = "Username for the admin user"
  type        = string
}

variable "docker_password" {
  description = "Password for the admin user"
  type        = string
  sensitive   = true
}

variable "hitrust_assessment_name" {
  type = string
}

variable "admin_ip" {
  type        = string
  description = "IP address of the admin user for network ACL whitelisting"
}

variable "cloudpc_ip" {
  type        = string
  description = "Trusted Cloud PC IP/CIDR for network ACL whitelisting"
}
