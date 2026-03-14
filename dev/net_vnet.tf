resource "azurerm_virtual_network" "dev" {
  #checkov:skip=CKV_AZURE_183:DDoS Standard not cost-justified; network protected by Palo Alto firewall and NSGs
  provider            = azurerm.dev
  name                = "vnet-dev"
  address_space       = ["10.30.0.0/16"]
  location            = azurerm_resource_group.networking.location
  resource_group_name = azurerm_resource_group.networking.name

  dns_servers = [
    "10.10.1.10",
    "10.10.1.11"
  ]

  tags = local.required_tags
}

resource "azurerm_subnet" "servers" {
  provider             = azurerm.dev
  name                 = "servers-subnet"
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = azurerm_virtual_network.dev.name
  address_prefixes     = ["10.30.1.0/24"]
}

resource "azurerm_subnet" "workers" {
  provider             = azurerm.dev
  name                 = "workers-subnet"
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = azurerm_virtual_network.dev.name
  address_prefixes     = ["10.30.2.0/24"]
}

resource "azurerm_network_security_group" "nsg_servers" {
  provider            = azurerm.dev
  name                = "nsg-servers"
  location            = azurerm_resource_group.networking.location
  resource_group_name = azurerm_resource_group.networking.name

  tags = local.required_tags
}

resource "azurerm_network_security_group" "nsg_workers" {
  provider            = azurerm.dev
  name                = "nsg-workers"
  location            = azurerm_resource_group.networking.location
  resource_group_name = azurerm_resource_group.networking.name

  tags = local.required_tags
}

resource "azurerm_subnet_network_security_group_association" "servers_assoc" {
  provider                  = azurerm.dev
  subnet_id                 = azurerm_subnet.servers.id
  network_security_group_id = azurerm_network_security_group.nsg_servers.id
}

resource "azurerm_subnet_network_security_group_association" "workers_assoc" {
  provider                  = azurerm.dev
  subnet_id                 = azurerm_subnet.workers.id
  network_security_group_id = azurerm_network_security_group.nsg_workers.id
}

# Route Tables
resource "azurerm_route_table" "rtb_default" {
  provider            = azurerm.dev
  name                = "rtb-default"
  location            = azurerm_resource_group.networking.location
  resource_group_name = azurerm_resource_group.networking.name

  tags = local.required_tags
}

resource "azurerm_route" "default_to_fw" {
  provider               = azurerm.dev
  name                   = "default-to-dev"
  resource_group_name    = azurerm_resource_group.networking.name
  route_table_name       = azurerm_route_table.rtb_default.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = "10.99.2.4" # dev private IP
}

resource "azurerm_subnet_route_table_association" "servers_rt_assoc" {
  provider       = azurerm.dev
  subnet_id      = azurerm_subnet.servers.id
  route_table_id = azurerm_route_table.rtb_default.id
}

resource "azurerm_subnet_route_table_association" "workers_rt_assoc" {
  provider       = azurerm.dev
  subnet_id      = azurerm_subnet.workers.id
  route_table_id = azurerm_route_table.rtb_default.id
}

resource "azurerm_virtual_network_peering" "dev_to_firewall" {
  provider                     = azurerm.dev
  name                         = "dev-to-firewall"
  resource_group_name          = azurerm_virtual_network.dev.resource_group_name
  virtual_network_name         = azurerm_virtual_network.dev.name
  remote_virtual_network_id    = module.remote_state.firewall.outputs.vnet_id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "dev_to_identity" {
  provider                     = azurerm.dev
  name                         = "dev-to-identity"
  resource_group_name          = azurerm_virtual_network.dev.resource_group_name
  virtual_network_name         = azurerm_virtual_network.dev.name
  remote_virtual_network_id    = module.remote_state.identity.outputs.vnet_id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}
