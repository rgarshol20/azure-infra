variable "location" {
  type        = string
  description = "Azure region"
  default     = "westus"
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
variable "billings_subscription_id" {
  type = string
}
variable "tenant_id" {
  type = string
}
variable "client_id" {
  type = string
}
variable "client_secret" {
  type = string
}

variable "admin_ip" {
  type        = string
  description = "IP address of the admin user"
}

variable "admin_username" {
  type = string
}
variable "docker_username" {
  type = string
}

variable "docker_password" {
  type      = string
  sensitive = true
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "ahds_password" {
  type = string
}

variable "firewall_serial_number" {
  type = string
}

variable "firewall_hostname" {
  type = string
}

variable "panorama_hostname" {
  type = string
}