variable "name" {
  description = "Subnet name"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "virtual_network_name" {
  description = "Parent virtual network name"
  type        = string
}

variable "address_prefixes" {
  description = "Subnet address prefixes (CIDR)"
  type        = list(string)

  validation {
    condition     = length(var.address_prefixes) > 0
    error_message = "At least one address prefix is required"
  }
}

variable "network_security_group_id" {
  description = "Network security group ID to associate (optional)"
  type        = string
  default     = null
}
