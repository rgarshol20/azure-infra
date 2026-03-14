variable "resource_group_name" {
  description = "Resource group to deploy into"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID (required for Key Vault)"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for ACI VNet integration (must have Microsoft.ContainerInstance/containerGroups delegation)"
  type        = string
}

variable "container_image" {
  description = "Docker image for the ACI container (e.g. dockerhub-user/palo-alto-backup:latest)"
  type        = string
}

variable "allowed_subnet_ids" {
  description = "Subnet IDs allowed to reach Key Vault (in addition to the function app subnet)"
  type        = list(string)
  default     = []
}

variable "devices" {
  description = "List of PAN-OS devices to back up"
  type = list(object({
    name        = string
    secret_name = string
    type        = string # "panorama" or "firewall"
  }))
  default = [
    {
      name        = "azure-prod-panorama"
      secret_name = "palo-alto-backup-azure-prod-panorama"
      type        = "panorama"
    },
    {
      name        = "azure-prod-firewall"
      secret_name = "palo-alto-backup-azure-prod-firewall"
      type        = "firewall"
    }
  ]
}

variable "github_secret_name" {
  description = "Key Vault secret name containing GitHub PAT and repo details"
  type        = string
  default     = "palo-alto-backup-github-token"
}

variable "ses_smtp_secret_name" {
  description = "Key Vault secret name containing SES SMTP credentials"
  type        = string
  default     = "palo-alto-backup-ses-smtp"
}

variable "ses_sender" {
  description = "Verified SES sender email address"
  type        = string
}

variable "ses_recipient" {
  description = "Alert recipient email address"
  type        = string
}

variable "ses_smtp_host" {
  description = "SES SMTP host"
  type        = string
  default     = "email-smtp.us-west-2.amazonaws.com"
}

variable "backup_container" {
  description = "Blob container name for config archives"
  type        = string
  default     = "firewall-configs"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "deploy_principal_id" {
  description = "Object ID of the service principal running Terraform (granted KV secrets CRUD for deployment)"
  type        = string
  default     = ""
}

variable "admin_object_ids" {
  description = "Object IDs of user accounts granted Get/List/Set on Key Vault (for manual secret population)"
  type        = list(string)
  default     = []
}

variable "docker_username" {
  description = "Docker Hub username or email for pulling the container image"
  type        = string
  default     = ""
}

variable "docker_password" {
  description = "Docker Hub password for pulling the container image"
  type        = string
  sensitive   = true
  default     = ""
}

variable "deployment_name" {
  description = "Human-readable deployment label used in email subjects and report titles (e.g. 'Azure', 'DDE')"
  type        = string
  default     = "Azure"
}

