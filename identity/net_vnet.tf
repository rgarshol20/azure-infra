resource "azurerm_virtual_network" "identity" {
  provider            = azurerm.identity
  name                = "vnet-identity"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.networking.location
  resource_group_name = azurerm_resource_group.networking.name

  dns_servers = [
    "10.10.1.10",
    "10.10.1.11"
  ]

  tags = local.required_tags
}

# Subnets
resource "azurerm_subnet" "ad" {
  provider             = azurerm.identity
  name                 = "ad-subnet"
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = azurerm_virtual_network.identity.name
  address_prefixes     = ["10.10.1.0/24"]
}

# Network Security Groups
resource "azurerm_network_security_group" "nsg_ad" {
  provider            = azurerm.identity
  name                = "nsg-ad"
  location            = azurerm_resource_group.networking.location
  resource_group_name = azurerm_resource_group.networking.name

  tags = local.required_tags
}

# NSG Associations
resource "azurerm_subnet_network_security_group_association" "ad_assoc" {
  provider                  = azurerm.identity
  subnet_id                 = azurerm_subnet.ad.id
  network_security_group_id = azurerm_network_security_group.nsg_ad.id
}

# Route Tables
resource "azurerm_route_table" "rtb_default" {
  provider            = azurerm.identity
  name                = "rtb-default"
  location            = azurerm_resource_group.networking.location
  resource_group_name = azurerm_resource_group.networking.name

  tags = local.required_tags
}

resource "azurerm_route" "default_to_fw" {
  provider               = azurerm.identity
  name                   = "default-to-identity"
  resource_group_name    = azurerm_resource_group.networking.name
  route_table_name       = azurerm_route_table.rtb_default.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = "10.99.2.4" # identity private IP
}

# Route table associations
resource "azurerm_subnet_route_table_association" "ad_rt_assoc" {
  provider       = azurerm.identity
  subnet_id      = azurerm_subnet.ad.id
  route_table_id = azurerm_route_table.rtb_default.id
}

resource "azurerm_virtual_network_peering" "identity_to_firewall" {
  provider                     = azurerm.identity
  name                         = "identity-to-firewall"
  resource_group_name          = azurerm_virtual_network.identity.resource_group_name
  virtual_network_name         = azurerm_virtual_network.identity.name
  remote_virtual_network_id    = module.remote_state.firewall.outputs.vnet_id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "identity_to_prod" {
  provider                     = azurerm.identity
  name                         = "identity-to-prod"
  resource_group_name          = azurerm_virtual_network.identity.resource_group_name
  virtual_network_name         = azurerm_virtual_network.identity.name
  remote_virtual_network_id    = module.remote_state.prod.outputs.vnet_id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "identity_to_dev" {
  provider                     = azurerm.identity
  name                         = "identity-to-dev"
  resource_group_name          = azurerm_virtual_network.identity.resource_group_name
  virtual_network_name         = azurerm_virtual_network.identity.name
  remote_virtual_network_id    = module.remote_state.dev.outputs.vnet_id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "identity_to_dashboard" {
  provider                     = azurerm.identity
  name                         = "identity-to-dashboard"
  resource_group_name          = azurerm_virtual_network.identity.resource_group_name
  virtual_network_name         = azurerm_virtual_network.identity.name
  remote_virtual_network_id    = module.remote_state.dashboard.outputs.vnet_id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}
