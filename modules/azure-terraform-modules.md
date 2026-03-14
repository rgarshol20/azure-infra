## Repo Context
- Repository: `azure-infra` (and `azure-dde-infra` for DDE tenant)
- Module path: `modules/<module-name>/`
- Each module: `main.tf`, `variables.tf`, `outputs.tf`
- Provider: `azurerm` (~>4.x)
- Naming convention: `<resource-abbrev>-<env>-<region>-<purpose>`
- All modules must pass Checkov HIPAA scans
- Tags input is required on every module — sourced from Tagging module output

# Azure Terraform Modules

Reusable modules for the `azure-infra` and `azure-dde-infra` repositories. Modules are prioritized by compliance impact, frequency of reuse, and dependency order.

**Module criteria:** Gets a module if it's built multiple times in production (Server, NSG) or built identically across dev/prod environments (VNet, Key Vault). Dependency modules (VNet, Tagging) should be built first as downstream modules consume their outputs.

---

## Priority 1: Diagnostic Settings

**Why first:** Directly addresses the critical log retention compliance gap. This module gets attached to *every* resource — most reused module in the entire codebase.

**What it does:**

- Configures Azure Diagnostic Settings on any resource
- Ships logs to Storage Account (6-year HIPAA archive) AND Log Analytics Workspace (30–90 day hot query) simultaneously
- Standardizes which log categories are enabled per resource type
- Ensures no resource gets deployed without audit logging

**Inputs:**

- `target_resource_id` — the resource to attach diagnostics to
- `log_analytics_workspace_id` — hot query destination
- `storage_account_id` — long-term archive destination
- `log_categories` — list of log categories to enable (defaults per resource type)
- `metric_categories` — list of metric categories to enable
- `tags` — inherited from tagging module

**Outputs:**

- `diagnostic_setting_id`

**Consumed by:** Every other module (Server, Key Vault, Storage Account, etc.) calls this as a child module.

---

## Priority 2: VNet

**Why:** Foundation module. Hub-spoke model is built identically in dev/prod. All other network resources (NSG, Private Endpoints, Servers) depend on VNet outputs.

**What it does:**

- Creates VNet with configurable address space
- Defines subnets with service endpoints and delegation
- Configures VNet peering (hub-spoke)
- Enables VNet flow logs to Storage Account for compliance
- Attaches diagnostic settings via the Diagnostic Settings module

**Inputs:**

- `vnet_name` — follows naming convention: `vnet-<env>-<region>-<purpose>`
- `address_space` — CIDR block(s)
- `subnets` — map of subnet name → CIDR, service endpoints, delegations, NSG association
- `peering_config` — optional hub VNet ID for spoke peering
- `dns_servers` — custom DNS if applicable
- `log_analytics_workspace_id` — passed through to diagnostics
- `storage_account_id` — passed through to diagnostics
- `tags`

**Outputs:**

- `vnet_id`
- `vnet_name`
- `subnet_ids` — map of subnet name → ID
- `subnet_address_prefixes`

---

## Priority 3: NSG

**Why:** Attached to every subnet and NIC. HIPAA zone segmentation requires consistent deny-by-default rules. Tightly coupled with VNet module.

**What it does:**

- Creates NSG with configurable security rules
- Enforces deny-by-default baseline with explicit allow rules
- Supports standard rule sets (e.g., web tier, app tier, data tier, management)
- Associates NSG to subnet or NIC
- Attaches diagnostic settings for NSG flow logs

**Inputs:**

- `nsg_name` — follows naming convention: `nsg-<env>-<region>-<purpose>`
- `security_rules` — list of rule objects (priority, direction, access, protocol, ports, source/destination)
- `subnet_id` — optional, for subnet association
- `baseline_rules` — boolean to include standard deny-by-default rules
- `log_analytics_workspace_id`
- `storage_account_id`
- `tags`

**Outputs:**

- `nsg_id`
- `nsg_name`

**Notes:** Consider pre-built rule sets as local variables — `web_tier_rules`, `app_tier_rules`, `data_tier_rules` — that consumers can merge with custom rules.

---

## Priority 4: Server (VM)

**Why:** Most frequently built resource in production. Standardizes OS config, disk encryption, backup policy assignment, and diagnostic settings attachment.

**What it does:**

- Creates Windows or Linux VM with standardized configuration
- Configures OS disk and optional data disks with encryption
- Attaches NIC to specified subnet with NSG
- Registers VM with Recovery Services Vault backup policy
- Installs standard extensions (monitoring agent, dependency agent)
- Attaches diagnostic settings

**Inputs:**

- `vm_name` — follows naming convention: `vm-<env>-<role>-<number>`
- `vm_size` — SKU
- `os_type` — `windows` or `linux`
- `os_image` — publisher, offer, SKU, version
- `subnet_id`
- `nsg_id` — optional NIC-level NSG
- `admin_username`
- `admin_password` or `ssh_public_key` — sourced from Key Vault
- `data_disks` — list of disk size/type
- `backup_policy_id` — Recovery Services Vault policy
- `key_vault_id` — for disk encryption key
- `log_analytics_workspace_id`
- `storage_account_id`
- `tags`

**Outputs:**

- `vm_id`
- `vm_name`
- `private_ip_address`
- `nic_id`

---

## Priority 5: Key Vault

**Why:** Built identically in dev/prod. Central to secrets management, disk encryption keys, and certificate storage. Needs consistent access policies and network restrictions.

**What it does:**

- Creates Key Vault with soft delete and purge protection enabled
- Configures access policies or RBAC authorization
- Sets network ACLs (deny by default, allow specific subnets/IPs)
- Optionally creates private endpoint via Private Endpoints module
- Attaches diagnostic settings

**Inputs:**

- `key_vault_name` — follows naming convention: `kv-<env>-<region>-<purpose>`
- `sku_name` — `standard` or `premium`
- `enabled_for_disk_encryption` — boolean
- `enabled_for_deployment` — boolean
- `enabled_for_template_deployment` — boolean
- `access_policies` — list of object ID → permissions mappings
- `network_acls` — default action, allowed subnet IDs, allowed IPs
- `private_endpoint_subnet_id` — optional, triggers private endpoint creation
- `log_analytics_workspace_id`
- `storage_account_id`
- `tags`

**Outputs:**

- `key_vault_id`
- `key_vault_uri`
- `key_vault_name`

---

## Priority 6: Storage Account

**Why:** Repeated across environments. Primary target for the log archive (lifecycle tiers: Hot → Cool at 90d → Archive at 1yr). Also used for general data and backups.

**What it does:**

- Creates Storage Account with encryption enforced
- Configures lifecycle management policies (Hot → Cool → Archive tiers)
- Enforces HTTPS-only (`enable_https_traffic_only`)
- Sets network rules (deny by default, allow specific subnets)
- Configures blob versioning and soft delete for ransomware protection
- Optionally creates private endpoint
- Attaches diagnostic settings

**Inputs:**

- `storage_account_name` — follows naming convention: `st<env><region><purpose>` (no hyphens, 3–24 chars)
- `account_tier` — `Standard` or `Premium`
- `account_replication_type` — `LRS`, `GRS`, `ZRS`, etc.
- `account_kind` — `StorageV2`
- `lifecycle_rules` — list of rules (move to Cool after X days, Archive after Y days, delete after Z days)
- `containers` — list of container names and access levels
- `network_rules` — default action, allowed subnet IDs, allowed IPs
- `private_endpoint_subnet_id` — optional
- `blob_soft_delete_days` — default 90
- `log_analytics_workspace_id`
- `storage_account_id` — for diagnostics (uses a separate storage account, not itself)
- `tags`

**Outputs:**

- `storage_account_id`
- `storage_account_name`
- `primary_blob_endpoint`
- `primary_access_key` — marked sensitive

**Notes:** The log archive storage account is the most critical instance. Lifecycle policy for log archive: Cool at 90 days, Archive at 365 days, delete at 2,555 days (7 years, buffer beyond 6-year HIPAA minimum).

---

## Priority 7: Recovery Services Vault

**Why:** Backup policies, vault config, soft delete for ransomware protection. HIPAA retention settings must be consistent. One per environment but config is identical.

**What it does:**

- Creates Recovery Services Vault
- Enables soft delete (14-day retention for deleted backups)
- Configures backup policies for VMs, SQL, and file shares
- Sets retention ranges aligned to HIPAA requirements
- Configures encryption settings
- Attaches diagnostic settings

**Inputs:**

- `vault_name` — follows naming convention: `rsv-<env>-<region>`
- `sku` — `Standard`
- `soft_delete_enabled` — boolean, default `true`
- `vm_backup_policies` — list of policy name, schedule, retention (daily/weekly/monthly/yearly)
- `sql_backup_policies` — list of policy configurations
- `file_share_backup_policies` — list of policy configurations
- `cross_region_restore_enabled` — boolean
- `log_analytics_workspace_id`
- `storage_account_id`
- `tags`

**Outputs:**

- `vault_id`
- `vault_name`
- `backup_policy_ids` — map of policy name → ID (consumed by Server module)

---

## Priority 8: Log Analytics Workspace

**Why:** Central to the monitoring story. Hot query window (30–90 day) for the log architecture. Receives diagnostics from all resources. Pairs with Diagnostic Settings module.

**What it does:**

- Creates Log Analytics Workspace
- Configures retention period (30–90 days for hot queries)
- Sets daily cap if needed to control costs
- Optionally configures solutions (e.g., VMInsights, SecurityInsights)
- Attaches diagnostic settings

**Inputs:**

- `workspace_name` — follows naming convention: `law-<env>-<region>`
- `sku` — `PerGB2018`
- `retention_in_days` — default 90
- `daily_quota_gb` — optional daily ingestion cap
- `solutions` — list of solution names to enable
- `tags`

**Outputs:**

- `workspace_id`
- `workspace_name`
- `workspace_resource_id` — full ARM resource ID (consumed by every Diagnostic Settings call)
- `primary_shared_key` — marked sensitive

**Notes:** This module is consumed by almost everything else indirectly — its `workspace_id` output feeds into every Diagnostic Settings module call.

---

## Priority 9: Private Endpoints

**Why:** HIPAA requires private network access to Storage Accounts and Key Vaults. Repetitive DNS zone and endpoint config that is error-prone without a module.

**What it does:**

- Creates Private Endpoint for a target resource
- Creates or associates Private DNS Zone for the service
- Links Private DNS Zone to VNet
- Creates DNS A record for the endpoint

**Inputs:**

- `endpoint_name` — follows naming convention: `pe-<env>-<resource_name>`
- `target_resource_id` — the resource to connect privately
- `subresource_names` — e.g., `["blob"]`, `["vault"]`
- `subnet_id` — subnet to place the endpoint in
- `private_dns_zone_name` — Azure Private Link DNS zone for the service type
- `vnet_id` — for DNS zone link
- `tags`

**Outputs:**

- `private_endpoint_id`
- `private_ip_address`
- `private_dns_zone_id`

**Notes:** Consider a lookup map for common `subresource_names` and `private_dns_zone_name` values per service type to reduce input complexity.

---

## Priority 10: Tagging

**Why:** Enforces naming and tagging standards across all resources. Implemented as a variable map or locals block consumed by every other module.

**What it does:**

- Defines required tags as a reusable locals block or variable map
- Merges resource-specific tags with organization-wide defaults
- Enforces required tags: `Environment`, `ManagedBy`, `Owner`, `CostCenter`, `Compliance`, `DataClassification`

**Implementation pattern:**

```hcl
# modules/tagging/main.tf
variable "environment" {}
variable "managed_by" { default = "terraform" }
variable "owner" {}
variable "cost_center" {}
variable "compliance" { default = "hipaa" }
variable "data_classification" { default = "phi" }
variable "extra_tags" { type = map(string); default = {} }

output "tags" {
  value = merge({
    Environment        = var.environment
    ManagedBy          = var.managed_by
    Owner              = var.owner
    CostCenter         = var.cost_center
    Compliance         = var.compliance
    DataClassification = var.data_classification
  }, var.extra_tags)
}
```

**Consumed by:** Every module. The `tags` output is passed as an input to all other modules.

---

## Module Dependency Graph

```
Tagging ─────────────────────────────────────┐
                                             │
Log Analytics Workspace ──────────┐          │
                                  │          │
Storage Account (archive) ────┐   │          │
                              │   │          │
Diagnostic Settings ◄─────────┤   │          │
    (attached to everything)  │   │          │
                              ▼   ▼          ▼
VNet ──► NSG                  all modules consume
  │                           tags, diagnostics
  ├──► Server (VM) ──► Recovery Services Vault
  │
  ├──► Key Vault ──► Private Endpoints
  │
  └──► Storage Account ──► Private Endpoints
```

Build order: Tagging → Log Analytics → Storage Account (archive) → Diagnostic Settings → VNet → NSG → then remaining modules in priority order.
