resource "azurerm_virtual_network" "dashboard" {
  #checkov:skip=CKV_AZURE_183:DDoS Standard not cost-justified; network protected by Palo Alto firewall and NSGs
  provider            = azurerm.dashboard
  name                = "vnet-dashboard"
  address_space       = ["10.5.0.0/16"]
  location            = azurerm_resource_group.networking.location
  resource_group_name = azurerm_resource_group.networking.name

  dns_servers = [
    "10.10.1.10",
    "10.10.1.11"
  ]

  tags = local.required_tags
}

resource "azurerm_subnet" "servers" {
  provider             = azurerm.dashboard
  name                 = "servers-subnet"
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = azurerm_virtual_network.dashboard.name
  address_prefixes     = ["10.5.1.0/24"]
}

resource "azurerm_subnet" "workers" {
  provider             = azurerm.dashboard
  name                 = "workers-subnet"
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = azurerm_virtual_network.dashboard.name
  address_prefixes     = ["10.5.2.0/24"]
}

resource "azurerm_network_security_group" "nsg_servers" {
  provider            = azurerm.dashboard
  name                = "nsg-servers"
  location            = azurerm_resource_group.networking.location
  resource_group_name = azurerm_resource_group.networking.name

  tags = local.required_tags
}

resource "azurerm_network_security_group" "nsg_workers" {
  provider            = azurerm.dashboard
  name                = "nsg-workers"
  location            = azurerm_resource_group.networking.location
  resource_group_name = azurerm_resource_group.networking.name

  tags = local.required_tags
}

resource "azurerm_subnet_network_security_group_association" "servers_assoc" {
  provider                  = azurerm.dashboard
  subnet_id                 = azurerm_subnet.servers.id
  network_security_group_id = azurerm_network_security_group.nsg_servers.id
}

resource "azurerm_subnet_network_security_group_association" "workers_assoc" {
  provider                  = azurerm.dashboard
  subnet_id                 = azurerm_subnet.workers.id
  network_security_group_id = azurerm_network_security_group.nsg_workers.id
}

# Route Tables
resource "azurerm_route_table" "rtb_default" {
  provider            = azurerm.dashboard
  name                = "rtb-default"
  location            = azurerm_resource_group.networking.location
  resource_group_name = azurerm_resource_group.networking.name

  tags = local.required_tags
}

resource "azurerm_route" "default_to_fw" {
  provider               = azurerm.dashboard
  name                   = "default-to-dashboard"
  resource_group_name    = azurerm_resource_group.networking.name
  route_table_name       = azurerm_route_table.rtb_default.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = "10.99.2.4" # dashboard private IP
}

resource "azurerm_subnet_route_table_association" "servers_rt_assoc" {
  provider       = azurerm.dashboard
  subnet_id      = azurerm_subnet.servers.id
  route_table_id = azurerm_route_table.rtb_default.id
}

resource "azurerm_subnet_route_table_association" "workers_rt_assoc" {
  provider       = azurerm.dashboard
  subnet_id      = azurerm_subnet.workers.id
  route_table_id = azurerm_route_table.rtb_default.id
}

resource "azurerm_virtual_network_peering" "dashboard_to_firewall" {
  provider                     = azurerm.dashboard
  name                         = "dashboard-to-firewall"
  resource_group_name          = azurerm_virtual_network.dashboard.resource_group_name
  virtual_network_name         = azurerm_virtual_network.dashboard.name
  remote_virtual_network_id    = module.remote_state.firewall.outputs.vnet_id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "dashboard_to_identity" {
  provider                     = azurerm.dashboard
  name                         = "dashboard-to-identity"
  resource_group_name          = azurerm_virtual_network.dashboard.resource_group_name
  virtual_network_name         = azurerm_virtual_network.dashboard.name
  remote_virtual_network_id    = module.remote_state.identity.outputs.vnet_id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}
