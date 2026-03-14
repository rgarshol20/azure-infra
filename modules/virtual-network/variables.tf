variable "name" {
  description = "Virtual network name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "address_space" {
  description = "Address space CIDR blocks"
  type        = list(string)

  validation {
    condition     = length(var.address_space) > 0
    error_message = "At least one address space is required"
  }
}

variable "dns_servers" {
  description = "DNS server IP addresses (optional)"
  type        = list(string)
  default     = null
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
