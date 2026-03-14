resource "azurerm_virtual_network" "firewall" {
  #checkov:skip=CKV_AZURE_183:DDoS Standard not cost-justified; network protected by Palo Alto firewall and NSGs
  provider            = azurerm.firewall
  name                = "vnet-firewall"
  address_space       = ["10.99.0.0/16"]
  location            = azurerm_resource_group.firewall.location
  resource_group_name = azurerm_resource_group.firewall.name

  dns_servers = [
    "10.10.1.10",
    "10.10.1.11"
  ]

  tags = local.required_tags
}

resource "azurerm_subnet" "mgmt" {
  provider             = azurerm.firewall
  name                 = "mgmt-subnet"
  resource_group_name  = azurerm_resource_group.firewall.name
  virtual_network_name = azurerm_virtual_network.firewall.name
  address_prefixes     = ["10.99.0.0/24"]
}

resource "azurerm_subnet" "backup_aci" {
  provider             = azurerm.firewall
  name                 = "backup-aci-subnet"
  resource_group_name  = azurerm_resource_group.firewall.name
  virtual_network_name = azurerm_virtual_network.firewall.name
  address_prefixes     = ["10.99.6.0/24"]

  delegation {
    name = "aci-delegation"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "public" {
  provider             = azurerm.firewall
  name                 = "public-subnet"
  resource_group_name  = azurerm_resource_group.firewall.name
  virtual_network_name = azurerm_virtual_network.firewall.name
  address_prefixes     = ["10.99.1.0/24"]
}

resource "azurerm_subnet" "private" {
  provider             = azurerm.firewall
  name                 = "private-subnet"
  resource_group_name  = azurerm_resource_group.firewall.name
  virtual_network_name = azurerm_virtual_network.firewall.name
  address_prefixes     = ["10.99.2.0/24"]
}


resource "azurerm_subnet" "twingate" {
  provider             = azurerm.firewall
  name                 = "twingate-subnet"
  resource_group_name  = azurerm_resource_group.firewall.name
  virtual_network_name = azurerm_virtual_network.firewall.name
  address_prefixes     = ["10.99.5.0/24"]

  delegation {
    name = "aci-delegation"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}


resource "azurerm_route_table" "private_rt" {
  provider            = azurerm.firewall
  name                = "rt-private"
  location            = azurerm_resource_group.firewall.location
  resource_group_name = azurerm_resource_group.firewall.name

  tags = local.required_tags
}

resource "azurerm_route" "private_default" {
  provider               = azurerm.firewall
  name                   = "default-route"
  resource_group_name    = azurerm_resource_group.firewall.name
  route_table_name       = azurerm_route_table.private_rt.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = "10.99.2.4"
}

resource "azurerm_subnet_route_table_association" "private_assoc" {
  provider       = azurerm.firewall
  subnet_id      = azurerm_subnet.private.id
  route_table_id = azurerm_route_table.private_rt.id
}

resource "azurerm_route_table" "twingate_rt" {
  provider            = azurerm.firewall
  name                = "rt-twingate"
  location            = azurerm_resource_group.firewall.location
  resource_group_name = azurerm_resource_group.firewall.name

  tags = local.required_tags
}

resource "azurerm_route" "twingate_default" {
  provider               = azurerm.firewall
  name                   = "default-route"
  resource_group_name    = azurerm_resource_group.firewall.name
  route_table_name       = azurerm_route_table.twingate_rt.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = "10.99.2.4"
}

resource "azurerm_subnet_route_table_association" "twingate_assoc" {
  provider       = azurerm.firewall
  subnet_id      = azurerm_subnet.twingate.id
  route_table_id = azurerm_route_table.twingate_rt.id
}

resource "azurerm_virtual_network_peering" "networking_to_identity" {
  provider                     = azurerm.firewall
  name                         = "firewall-to-identity"
  resource_group_name          = azurerm_virtual_network.firewall.resource_group_name
  virtual_network_name         = azurerm_virtual_network.firewall.name
  remote_virtual_network_id    = module.remote_state.identity.outputs.vnet_id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "networking_to_prod" {
  provider                     = azurerm.firewall
  name                         = "firewall-to-prod"
  resource_group_name          = azurerm_virtual_network.firewall.resource_group_name
  virtual_network_name         = azurerm_virtual_network.firewall.name
  remote_virtual_network_id    = module.remote_state.prod.outputs.vnet_id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "networking_to_dev" {
  provider                     = azurerm.firewall
  name                         = "firewall-to-dev"
  resource_group_name          = azurerm_virtual_network.firewall.resource_group_name
  virtual_network_name         = azurerm_virtual_network.firewall.name
  remote_virtual_network_id    = module.remote_state.dev.outputs.vnet_id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "networking_to_dashboard" {
  provider                     = azurerm.firewall
  name                         = "firewall-to-dashboard"
  resource_group_name          = azurerm_virtual_network.firewall.resource_group_name
  virtual_network_name         = azurerm_virtual_network.firewall.name
  remote_virtual_network_id    = module.remote_state.dashboard.outputs.vnet_id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}