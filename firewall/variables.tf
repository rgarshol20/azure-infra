variable "location" {
  type        = string
  description = "Azure region"
  default     = "westus"
}


variable "mde_win" {
  type = string
}
variable "mde_lin" {
  type = string
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

variable "admin_ips" {
  type        = list(string)
  description = "IP addresses of the admin users"
  default     = ["24.5.104.220/32", "107.205.9.100/32", "44.246.134.14/32"]
}

variable "docker_username" {
  type = string
}

variable "docker_password" {
  type      = string
  sensitive = true
}

variable "syslog_username" {
  type = string
}

variable "syslog_password" {
  type      = string
  sensitive = true
}

variable "admin_username" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "public_key" {
  type      = string
  sensitive = true
}
variable "twingate_network" {}
variable "twingate_prophetic_magpie_access_token" {}
variable "twingate_prophetic_magpie_refresh_token" {}
variable "twingate_outstanding_hampster_access_token" {}
variable "twingate_outstanding_hampster_refresh_token" {}
variable "twingate_url_slug" {}

variable "hitrust_assessment_name" {
  type = string
}

variable "ses_sender" {
  description = "Verified SES sender email for Palo Alto backup/audit alerts"
  type        = string
}

variable "ses_recipient" {
  description = "Alert recipient email for Palo Alto backup/audit reports"
  type        = string
}

variable "container_image" {
  description = "Docker image for the palo-alto-backup ACI container (built and pushed by CI)"
  type        = string
}

variable "decommission_admin_password" {
  description = "Placeholder admin password for decommission-bound resources. These resources are scheduled for destruction June 2026 and should not be running."
  type        = string
  sensitive   = true
  default     = "DECOMMISSION-NOT-ACTIVE"
}
