# Reusable Terraform Modules

This directory contains reusable terraform modules for the azure-infra repository. These modules eliminate duplication and provide consistent patterns for common resources.

## Module Structure

```
modules/
├── resource-group/    # Reusable resource group creation
├── tags/              # Standard tagging module
├── remote-state/      # Remote state data sources
├── storage-account/   # Storage account with encryption and network security
├── key-vault/         # Key vault with RBAC and soft delete
├── virtual-network/   # Virtual network creation
└── subnet/            # Subnet with optional NSG association
```

## Module: resource-group

Creates an Azure resource group with standard inputs and outputs.

### Usage

```hcl
module "my_resource_group" {
  source = "../modules/resource-group"

  name     = "rg-example-logs"
  location = "eastus"
  tags     = local.required_tags
}

# Reference the created resource group
resource "azurerm_log_analytics_workspace" "example" {
  name                = "example-law"
  location            = module.my_resource_group.location
  resource_group_name = module.my_resource_group.name
}
```

### Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| name | string | yes | Name of the resource group |
| location | string | yes | Azure region (e.g., eastus, centralus) |
| tags | map(string) | no | Tags to apply to the resource group |

### Outputs

| Name | Description |
|------|-------------|
| resource_group | Complete resource group object |
| name | Resource group name |
| location | Resource group location |
| id | Resource group ID |

---

## Module: tags

Generates the standard required tags map based on the tagging standard in `/git/infrastructure-docs/compliance/tagging-standard.md`.

### Usage

```hcl
module "tags" {
  source = "../modules/tags"

  environment         = "production"
  data_classification = "phi"
  compliance_scope    = "hipaa-soc2-hitrust"
  cost_center         = "it"
  owner               = "it-security"
  managed_by          = "terraform"
}

# Use the tags
resource "azurerm_resource_group" "example" {
  name     = "rg-example"
  location = "eastus"
  tags     = module.tags.required_tags
}
```

### Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| environment | string | yes | - | production, development, or shared |
| data_classification | string | yes | - | phi, confidential, internal, or public |
| compliance_scope | string | yes | - | Compliance frameworks (e.g., hipaa-soc2-hitrust) |
| cost_center | string | no | "it" | Cost center for billing |
| owner | string | no | "it-security" | Team or individual responsible |
| managed_by | string | no | "terraform" | How the resource is managed |

### Outputs

| Name | Description |
|------|-------------|
| required_tags | Standard tags map for all resources |

### Validation

The module includes validation rules to ensure:
- `environment` is one of: production, development, shared
- `data_classification` is one of: phi, confidential, internal, public

---

## Module: remote-state

Provides all terraform remote state data sources for cross-module references. Eliminates duplication of `terraform_remote_state` blocks across modules.

### Usage

```hcl
module "remote_state" {
  source = "../modules/remote-state"

  state_resource_group  = "rg-main-terraform"
  state_storage_account = "acme-health-terraform-state"
  state_container       = "terraform-state"
  use_azuread_auth      = true
  use_oidc              = true
}

# Reference outputs from other modules
resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  virtual_network_name = module.remote_state.main.outputs.vnet_name
  resource_group_name  = module.remote_state.main.outputs.networking_rg_name
  address_prefixes     = ["10.0.1.0/24"]
}
```

### Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| state_resource_group | string | no | "rg-main-terraform" | Resource group with state storage |
| state_storage_account | string | no | "acme-health-terraform-state" | State storage account name |
| state_container | string | no | "terraform-state" | State container name |
| use_azuread_auth | bool | no | true | Use Azure AD authentication |
| use_oidc | bool | no | true | Use OIDC (for CI/CD) |

### Outputs

| Name | Description |
|------|-------------|
| logging | Logging module remote state |
| main | Main module remote state |
| identity | Identity module remote state |
| firewall | Firewall module remote state |
| prod | Production module remote state |
| dev | Development module remote state |

---

## Complete Example

Here's a complete example showing how to use all three modules together:

```hcl
# In a new module or environment

# Generate standard tags
module "tags" {
  source = "../modules/tags"

  environment         = "production"
  data_classification = "phi"
  compliance_scope    = "hipaa-soc2-hitrust"
}

# Create resource group
module "networking_rg" {
  source = "../modules/resource-group"

  name     = "rg-example-networking"
  location = "eastus"
  tags     = module.tags.required_tags
}

# Access remote state from other modules
module "remote_state" {
  source = "../modules/remote-state"
}

# Use the remote state and created resources
resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  virtual_network_name = module.remote_state.main.outputs.vnet_name
  resource_group_name  = module.networking_rg.name
  address_prefixes     = ["10.0.1.0/24"]
}
```

---

## Migration Strategy

**Important:** These modules are designed for NEW resources and future use. Replacing existing resource blocks with module calls would change resource addresses in terraform state, requiring state migration.

### For New Resources

Use these modules for all new infrastructure:
```hcl
module "new_rg" {
  source   = "../modules/resource-group"
  name     = "rg-new-feature"
  location = var.location
  tags     = module.tags.required_tags
}
```

### For Existing Resources

Existing resources should remain as direct `resource` blocks until a planned state migration:
```hcl
# Keep existing resources as-is
resource "azurerm_resource_group" "logging" {
  name     = "rg-logging-logs"
  location = var.location
  tags     = local.required_tags
}
```

---

## Module Dependencies

Each module includes `versions.tf` with:
- Terraform version constraint: `>= 1.0`
- Azure provider version: `~> 4.0` (resource-group module only)

Modules are tested with:
- Terraform 1.7.5
- Azure provider 4.x

---

## Validation

All modules can be validated independently:

```bash
cd modules/resource-group && terraform init && terraform validate
cd modules/tags && terraform validate
cd modules/remote-state && terraform validate
```

---

## Contributing

When adding new reusable modules:

1. Create module directory under `modules/`
2. Include: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`
3. Add validation rules for required variables
4. Document usage in this file
5. Test with `terraform validate` before committing

---

## Module: storage-account

Creates an Azure storage account with HIPAA-compliant security features including optional customer-managed encryption, network rules, and managed identity support.

### Usage

```hcl
# Basic storage account
module "logs_storage" {
  source = "../modules/storage-account"

  name                = "mylogsstorage01"
  resource_group_name = azurerm_resource_group.logging.name
  location            = azurerm_resource_group.logging.location
  account_tier        = "Standard"
  account_replication_type = "LRS"
  
  network_rules = {
    default_action = "Allow"
    ip_rules       = ["1.2.3.4", "5.6.7.8"]
    bypass         = ["AzureServices"]
  }
  
  tags = module.tags.required_tags
}

# Storage account with customer-managed key encryption
module "encrypted_storage" {
  source = "../modules/storage-account"

  name                = "encryptedstorage01"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  identity_type = "UserAssigned"
  identity_ids  = [azurerm_user_assigned_identity.storage_identity.id]
  
  customer_managed_key = {
    key_vault_key_id          = azurerm_key_vault_key.storage_key.id
    user_assigned_identity_id = azurerm_user_assigned_identity.storage_identity.id
  }
  
  network_rules = {
    default_action = "Allow"
    ip_rules       = [var.admin_ip]
    bypass         = ["AzureServices"]
  }
  
  tags = module.tags.required_tags
}
```

### Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| name | string | yes | - | Storage account name (3-24 lowercase alphanumeric) |
| resource_group_name | string | yes | - | Resource group name |
| location | string | yes | - | Azure region |
| account_tier | string | no | "Standard" | Standard or Premium |
| account_replication_type | string | no | "LRS" | LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS |
| shared_access_key_enabled | bool | no | false | Enable shared access keys (disable for HIPAA) |
| allow_nested_items_to_be_public | bool | no | false | Allow public blob access |
| min_tls_version | string | no | "TLS1_2" | Minimum TLS version |
| public_network_access_enabled | bool | no | true | Enable public network access |
| network_rules | object | no | null | Network rules (default_action, ip_rules, bypass) |
| identity_type | string | no | null | SystemAssigned or UserAssigned |
| identity_ids | list(string) | no | null | User-assigned identity IDs |
| customer_managed_key | object | no | null | CMK config (key_vault_key_id, user_assigned_identity_id) |
| tags | map(string) | no | {} | Tags to apply |

### Outputs

| Name | Description |
|------|-------------|
| id | Storage account resource ID |
| name | Storage account name |
| primary_blob_endpoint | Primary blob endpoint |
| primary_blob_host | Primary blob host |
| storage_account | Complete storage account object |

### Security Features

- **Default: No shared access keys** - Disabled by default for HIPAA compliance
- **TLS 1.2 minimum** - Enforces secure transport
- **Optional CMK encryption** - Customer-managed keys via Key Vault
- **Network isolation** - IP-based access control with Azure service bypass
- **Managed identity** - User-assigned or system-assigned identity support

---

## Module: key-vault

Creates an Azure Key Vault with RBAC authorization, soft delete, and purge protection enabled by default for HIPAA compliance.

### Usage

```hcl
module "main_keyvault" {
  source = "../modules/key-vault"

  name                = "mycompany-main-kv"
  location            = azurerm_resource_group.security.location
  resource_group_name = azurerm_resource_group.security.name
  tenant_id           = var.tenant_id
  
  sku_name                   = "standard"
  soft_delete_retention_days = 90
  purge_protection_enabled   = true
  enable_rbac_authorization  = true
  
  tags = module.tags.required_tags
}
```

### Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| name | string | yes | - | Key vault name (3-24 alphanumeric and hyphens) |
| location | string | yes | - | Azure region |
| resource_group_name | string | yes | - | Resource group name |
| tenant_id | string | yes | - | Azure AD tenant ID |
| sku_name | string | no | "standard" | standard or premium |
| soft_delete_retention_days | number | no | 90 | Retention in days (7-90) |
| purge_protection_enabled | bool | no | true | Enable purge protection |
| enable_rbac_authorization | bool | no | true | Use RBAC (recommended) |
| tags | map(string) | no | {} | Tags to apply |

### Outputs

| Name | Description |
|------|-------------|
| id | Key vault resource ID |
| name | Key vault name |
| vault_uri | Key vault URI |
| key_vault | Complete key vault object |

### Compliance Features

- **RBAC authorization by default** - Modern access control vs legacy access policies
- **90-day soft delete** - Protects against accidental deletion
- **Purge protection enabled** - Prevents permanent deletion during retention period
- **HIPAA-ready configuration** - Meets healthcare compliance requirements

---

## Module: virtual-network

Creates an Azure virtual network with configurable address space and DNS servers.

### Usage

```hcl
module "prod_vnet" {
  source = "../modules/virtual-network"

  name                = "vnet-prod"
  location            = azurerm_resource_group.networking.location
  resource_group_name = azurerm_resource_group.networking.name
  address_space       = ["10.20.0.0/16"]
  
  dns_servers = ["10.10.1.10", "10.10.1.11"]
  
  tags = module.tags.required_tags
}
```

### Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| name | string | yes | - | Virtual network name |
| location | string | yes | - | Azure region |
| resource_group_name | string | yes | - | Resource group name |
| address_space | list(string) | yes | - | Address space CIDR blocks |
| dns_servers | list(string) | no | null | DNS server IP addresses |
| tags | map(string) | no | {} | Tags to apply |

### Outputs

| Name | Description |
|------|-------------|
| id | Virtual network resource ID |
| name | Virtual network name |
| address_space | Virtual network address space |
| virtual_network | Complete virtual network object |

---

## Module: subnet

Creates an Azure subnet with optional network security group association.

### Usage

```hcl
# Subnet without NSG
module "servers_subnet" {
  source = "../modules/subnet"

  name                 = "servers-subnet"
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = module.prod_vnet.name
  address_prefixes     = ["10.20.1.0/24"]
}

# Subnet with NSG association
module "workers_subnet" {
  source = "../modules/subnet"

  name                 = "workers-subnet"
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = module.prod_vnet.name
  address_prefixes     = ["10.20.2.0/24"]
  
  network_security_group_id = azurerm_network_security_group.workers_nsg.id
}
```

### Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| name | string | yes | - | Subnet name |
| resource_group_name | string | yes | - | Resource group name |
| virtual_network_name | string | yes | - | Parent virtual network name |
| address_prefixes | list(string) | yes | - | Subnet address prefixes (CIDR) |
| network_security_group_id | string | no | null | NSG ID to associate |

### Outputs

| Name | Description |
|------|-------------|
| id | Subnet resource ID |
| name | Subnet name |
| address_prefixes | Subnet address prefixes |
| subnet | Complete subnet object |

---

## Complete Example: Secure Storage Infrastructure

Here's a complete example using multiple modules together to create HIPAA-compliant storage infrastructure:

```hcl
# Tags
module "tags" {
  source = "../modules/tags"
  
  environment         = "production"
  data_classification = "phi"
  compliance_scope    = "hipaa-soc2-hitrust"
}

# Resource group
module "storage_rg" {
  source = "../modules/resource-group"
  
  name     = "rg-prod-storage"
  location = "centralus"
  tags     = module.tags.required_tags
}

# Key vault for encryption keys
module "storage_kv" {
  source = "../modules/key-vault"
  
  name                = "prod-storage-kv"
  location            = module.storage_rg.location
  resource_group_name = module.storage_rg.name
  tenant_id           = var.tenant_id
  
  tags = module.tags.required_tags
}

# Managed identity for storage encryption
resource "azurerm_user_assigned_identity" "storage" {
  name                = "storage-cmk-identity"
  resource_group_name = module.storage_rg.name
  location            = module.storage_rg.location
  tags                = module.tags.required_tags
}

# Grant identity access to key vault
resource "azurerm_role_assignment" "storage_kv_crypto" {
  scope                = module.storage_kv.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_user_assigned_identity.storage.principal_id
}

# Encryption key
resource "azurerm_key_vault_key" "storage" {
  name         = "storage-cmk"
  key_vault_id = module.storage_kv.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts     = ["encrypt", "decrypt", "sign", "verify", "wrapKey", "unwrapKey"]
}

# Storage account with CMK encryption
module "encrypted_storage" {
  source = "../modules/storage-account"
  
  name                = "prodencryptedstorage"
  resource_group_name = module.storage_rg.name
  location            = module.storage_rg.location
  
  identity_type = "UserAssigned"
  identity_ids  = [azurerm_user_assigned_identity.storage.id]
  
  customer_managed_key = {
    key_vault_key_id          = azurerm_key_vault_key.storage.id
    user_assigned_identity_id = azurerm_user_assigned_identity.storage.id
  }
  
  network_rules = {
    default_action = "Allow"
    ip_rules       = [var.admin_ip]
    bypass         = ["AzureServices"]
  }
  
  tags = module.tags.required_tags
}
```

