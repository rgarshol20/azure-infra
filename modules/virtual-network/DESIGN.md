# Virtual Network Module Design

## Purpose

Standardize virtual network, subnet, NSG, and route table creation across Azure infrastructure environments with consistent naming, tagging, and security patterns.

## Current State

Virtual network resources are currently created inline in each environment directory with significant duplication:
- VNet definitions scattered across main, dev, prod, dashboard
- NSG rules duplicated with slight variations
- Route table configurations inconsistent
- Peering relationships defined bilaterally (both sides of each connection)
- Subnet delegations and service endpoints vary by environment

## Target Interface

### Module Resources

The `virtual-network` module will create and manage:

1. **Virtual Network** (`azurerm_virtual_network`)
   - CIDR address space(s)
   - DNS servers (optional)
   - DDoS protection plan association (optional)

2. **Subnets** (`azurerm_subnet`)
   - Name, address prefix
   - Service endpoints (optional list)
   - Delegation configuration (optional)
   - Private endpoint network policies
   - Private link service network policies

3. **Network Security Groups** (`azurerm_network_security_group`)
   - Per-subnet NSG with rule definitions
   - Security rule priority auto-calculation
   - Default deny-all rule at lowest priority
   - Tag-based rule organization

4. **NSG-Subnet Associations** (`azurerm_subnet_network_security_group_association`)
   - One NSG per subnet (1:1 mapping)

5. **Route Tables** (`azurerm_route_table`)
   - Per-subnet route table (optional)
   - BGP route propagation control
   - Custom routes with next hop configuration

6. **Route Table Associations** (`azurerm_subnet_route_table_association`)
   - Associate route tables with subnets

7. **VNet Peering** (`azurerm_virtual_network_peering`)
   - Hub-spoke peering relationships
   - Allow forwarded traffic configuration
   - Gateway transit settings
   - Remote gateway usage

### Example Usage

```hcl
module "vnet" {
  source              = "../modules/virtual-network"
  name                = "production-vnet"
  location            = "centralus"
  resource_group_name = azurerm_resource_group.networking.name
  address_space       = ["10.0.0.0/16"]

  subnets = [
    {
      name             = "frontend"
      address_prefix   = "10.0.1.0/24"
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]

      nsg_rules = [
        {
          name                       = "allow-https-inbound"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "Internet"
          destination_address_prefix = "*"
        },
        {
          name                       = "allow-backend-outbound"
          priority                   = 110
          direction                  = "Outbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "1433"
          source_address_prefix      = "*"
          destination_address_prefix = "10.0.2.0/24"
        }
      ]

      routes = [
        {
          name                   = "to-firewall"
          address_prefix         = "0.0.0.0/0"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = "10.0.100.4"
        }
      ]
    },
    {
      name             = "backend"
      address_prefix   = "10.0.2.0/24"
      service_endpoints = ["Microsoft.Sql"]

      delegation = {
        name = "sql-delegation"
        service_delegation = {
          name    = "Microsoft.Sql/managedInstances"
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      }

      nsg_rules = [
        {
          name                       = "allow-frontend-inbound"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "1433"
          source_address_prefix      = "10.0.1.0/24"
          destination_address_prefix = "*"
        }
      ]
    }
  ]

  peerings = [
    {
      name                         = "prod-to-hub"
      remote_virtual_network_id    = module.hub_vnet.id
      allow_forwarded_traffic      = true
      allow_gateway_transit        = false
      use_remote_gateways          = true
    }
  ]

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

### Variable Structure

```hcl
variable "subnets" {
  description = "List of subnets to create"
  type = list(object({
    name                                          = string
    address_prefix                                = string
    service_endpoints                             = optional(list(string), [])
    private_endpoint_network_policies_enabled     = optional(bool, true)
    private_link_service_network_policies_enabled = optional(bool, true)

    delegation = optional(object({
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    }))

    nsg_rules = optional(list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    })), [])

    routes = optional(list(object({
      name                   = string
      address_prefix         = string
      next_hop_type          = string
      next_hop_in_ip_address = optional(string)
    })), [])
  }))
}

variable "peerings" {
  description = "List of VNet peering relationships"
  type = list(object({
    name                         = string
    remote_virtual_network_id    = string
    allow_forwarded_traffic      = optional(bool, false)
    allow_gateway_transit        = optional(bool, false)
    use_remote_gateways          = optional(bool, false)
  }))
  default = []
}
```

## Design Decisions

### Subnet-Centric Model

The module uses a **subnet-centric** approach where each subnet definition contains its NSG rules and route table configuration. This simplifies usage compared to separate NSG/route table blocks.

**Rationale:**
- Subnets, NSGs, and routes are tightly coupled in Azure network design
- Reduces chance of misconfiguration (orphaned NSGs, missing associations)
- Easier to review complete subnet security posture in one place
- Matches mental model: "this subnet needs these rules and these routes"

### NSG Rule Priority Auto-Calculation

NSG rules are specified with explicit priorities (user-provided). The module does NOT auto-calculate priorities.

**Rationale:**
- Priority conflicts are rare when users specify them explicitly
- Auto-calculation can mask conflicts until apply time
- Explicit priorities make intent clear in code review
- Azure allows priorities 100-4096, plenty of room for explicit assignment

However, the module WILL add a default deny-all rule at priority 4096 if not specified by the user.

### Peering: One-Sided Definition

VNet peering is defined **one-sided** in the module call. The user is responsible for creating the reciprocal peering.

**Rationale:**
- Terraform cannot create both sides in one apply without circular dependency
- Explicit reciprocal peering makes the relationship clear in both VNet configs
- Allows asymmetric peering configurations (different settings on each side)

**Alternative considered:** Create both sides via a separate `vnet-peering` module that takes both VNet IDs. Rejected due to requiring separate module invocation.

### Route Table: Per-Subnet or Shared

Route tables can be **per-subnet** (specified in subnet block) or **shared** (created separately and associated with multiple subnets).

The module supports **per-subnet** route tables only (inline in subnet definition).

**Rationale:**
- Per-subnet is the common case (e.g., frontend routes to firewall, backend routes direct)
- Shared route tables can be created outside the module and associated via `route_table_id` variable
- Keeps module interface simple while allowing advanced usage

### Service Endpoints vs. Private Endpoints

The module creates **service endpoints** (subnet-level configuration). **Private endpoints** are NOT part of this module.

**Rationale:**
- Private endpoints are resource-specific (tied to specific storage account, key vault, etc.)
- Private endpoints belong in the resource module (e.g., `key-vault`, `storage-account`)
- Service endpoints are subnet-level configuration and fit naturally here

## Future Enhancements

1. **NSG Flow Logs**: Add optional Network Watcher NSG flow log configuration per NSG
2. **DDoS Protection Plan**: Add module support for DDoS Standard plan association
3. **VNet Gateway**: Add optional VPN/ExpressRoute gateway creation
4. **Network Watcher**: Add optional Network Watcher resource per region
5. **Application Security Groups**: Add ASG creation and NSG rule ASG references

## Migration Strategy

**Phase 1**: Create module (this design phase)

**Phase 2**: Pilot in dev environment
- Create `dev` VNet using module alongside existing inline VNet
- Validate feature parity (subnets, NSG rules, routes, peering)
- Compare `terraform plan` output for differences
- Adjust module to match inline patterns

**Phase 3**: Import existing VNets to module
- Use `terraform import` to bring existing VNet resources under module management
- Refactor environment configs to use module
- Test in dev, then prod, firewall, dashboard

**Phase 4**: Deprecate inline VNet definitions
- Remove inline resource blocks
- Document module as standard pattern

## Open Questions

1. **NSG diagnostic settings**: Should the module create diagnostic settings for NSGs automatically, or leave that to environment config?
   - **Recommendation**: Environment config, because Log Analytics workspace is environment-specific

2. **Subnet naming convention**: Enforce naming pattern (e.g., `{vnet-name}-{subnet-name}-subnet`)?
   - **Recommendation**: No enforcement, allow user-specified names for flexibility

3. **Default NSG rules**: Include default allow-VNet rules, or start with pure deny-all?
   - **Recommendation**: Start with deny-all, require explicit rules. Align with zero-trust principles.

4. **Multiple address spaces**: Support multiple CIDR blocks in `address_space`?
   - **Recommendation**: Yes, Azure supports it, module should accept `list(string)` for address_space

## References

- Azure Virtual Network documentation: https://learn.microsoft.com/en-us/azure/virtual-network/
- Terraform azurerm_virtual_network: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network
- Terraform azurerm_subnet: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet
- Azure NSG best practices: https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview
