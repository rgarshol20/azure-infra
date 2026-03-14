# Basic VM Configuration
variable "name" {
  description = "Virtual machine name"
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

variable "size" {
  description = "VM size (e.g., Standard_D4s_v3)"
  type        = string
}

variable "zone" {
  description = "Availability zone (1, 2, or 3)"
  type        = string
  default     = null
}

# Authentication
variable "admin_username" {
  description = "Admin username"
  type        = string
  default     = "server-admin"
}

variable "admin_password" {
  description = "Admin password"
  type        = string
  sensitive   = true
}

# Network Configuration
variable "subnet_id" {
  description = "Subnet ID for NIC"
  type        = string
}

variable "private_ip_address" {
  description = "Static private IP address"
  type        = string
  default     = null
}

variable "nic_name" {
  description = "Override for NIC name (defaults to {name}-nic). Use to match an existing NIC name when migrating."
  type        = string
  default     = null
}

variable "network_security_group_id" {
  description = "NSG ID to associate with NIC"
  type        = string
  default     = null
}

variable "accelerated_networking_enabled" {
  description = "Enable accelerated networking"
  type        = bool
  default     = false
}

# OS Configuration
variable "os_disk_caching" {
  description = "OS disk caching mode"
  type        = string
  default     = "ReadWrite"
}

variable "os_disk_storage_account_type" {
  description = "OS disk storage account type"
  type        = string
  default     = "Premium_LRS"
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = null
}

variable "source_image_id" {
  description = "Custom image ID (for custom images)"
  type        = string
  default     = null
}

variable "source_image_publisher" {
  description = "Image publisher (used when source_image_id is null)"
  type        = string
  default     = "MicrosoftWindowsServer"
}

variable "source_image_offer" {
  description = "Image offer (used when source_image_id is null)"
  type        = string
  default     = "WindowsServer"
}

variable "source_image_sku" {
  description = "Image SKU (used when source_image_id is null)"
  type        = string
  default     = "2022-datacenter-azure-edition-hotpatch"
}

variable "source_image_version" {
  description = "Image version (used when source_image_id is null)"
  type        = string
  default     = "latest"
}

variable "patch_mode" {
  description = "VM patch mode"
  type        = string
  default     = "AutomaticByOS"
}

variable "patch_assessment_mode" {
  description = "VM patch assessment mode"
  type        = string
  default     = "AutomaticByPlatform"
}

# Security
variable "secure_boot_enabled" {
  description = "Enable secure boot"
  type        = bool
  default     = true
}

variable "vtpm_enabled" {
  description = "Enable vTPM"
  type        = bool
  default     = true
}

variable "encryption_at_host_enabled" {
  description = "Enable encryption at host"
  type        = bool
  default     = false
}

variable "disk_encryption_set_id" {
  description = "Disk Encryption Set ID for CMK encryption"
  type        = string
  default     = null
}

# Monitoring
variable "data_collection_rule_id" {
  description = "Data Collection Rule ID for Azure Monitor"
  type        = string
  default     = null
}

# Backup
variable "recovery_vault_id" {
  description = "Recovery Services Vault ID for backup"
  type        = string
  default     = null
}

variable "backup_policy_id" {
  description = "Backup policy ID"
  type        = string
  default     = null
}

variable "backup_resource_group_name" {
  description = "Resource group name for backup vault (defaults to VM resource group if not specified)"
  type        = string
  default     = null
}

# Optional Data Disks
variable "data_disks" {
  description = "List of data disks to attach"
  type = list(object({
    name                 = string
    disk_size_gb         = number
    lun                  = number
    caching              = string
    storage_account_type = string
  }))
  default = []
}

# Tags
variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
