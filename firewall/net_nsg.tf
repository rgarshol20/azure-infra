# Management NSG
resource "azurerm_network_security_group" "mgmt_nsg" {
  provider            = azurerm.firewall
  name                = "nsg-fw-mgmt"
  location            = var.location
  resource_group_name = azurerm_virtual_network.firewall.resource_group_name

  security_rule {
    name                       = "Allow-Admin-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = concat(var.admin_ips)
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Admin-HTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefixes    = concat(var.admin_ips)
    destination_address_prefix = "*"
  }

  tags = local.required_tags
}

# Public NSG
resource "azurerm_network_security_group" "public_nsg" {
  #checkov:skip=CKV_AZURE_9:Firewall public interface — Palo Alto VM-Series enforces perimeter policy; NSG is pass-through by design
  #checkov:skip=CKV_AZURE_10:Firewall public interface — Palo Alto VM-Series enforces perimeter policy; NSG is pass-through by design
  #checkov:skip=CKV_AZURE_160:Firewall public interface — Palo Alto VM-Series enforces perimeter policy; NSG is pass-through by design
  provider            = azurerm.firewall
  name                = "nsg-fw-public"
  location            = var.location
  resource_group_name = azurerm_virtual_network.firewall.resource_group_name

  security_rule {
    name                       = "Allow-All-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.required_tags
}

# Private NSG
resource "azurerm_network_security_group" "private_nsg" {
  provider            = azurerm.firewall
  name                = "nsg-fw-private"
  location            = var.location
  resource_group_name = azurerm_virtual_network.firewall.resource_group_name

  security_rule {
    name                       = "Allow-From-Firewall"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.99.2.4"
    destination_address_prefix = "*"
  }

  tags = local.required_tags
}

# Twingate NSG
resource "azurerm_network_security_group" "twingate_nsg" {
  provider            = azurerm.firewall
  name                = "nsg-fw-twingate"
  location            = var.location
  resource_group_name = azurerm_virtual_network.firewall.resource_group_name

  security_rule {
    name                       = "Allow-From-Firewall"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.99.2.4"
    destination_address_prefix = "*"
  }

  tags = local.required_tags
}

# AD NSG
resource "azurerm_network_security_group" "ad_nsg" {
  provider            = azurerm.firewall
  name                = "nsg-fw-ad"
  location            = var.location
  resource_group_name = azurerm_virtual_network.firewall.resource_group_name

  security_rule {
    name                       = "Allow-From-Firewall"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.99.2.4"
    destination_address_prefix = "*"
  }

  tags = local.required_tags
}

resource "azurerm_subnet_network_security_group_association" "mgmt_assoc" {
  provider                  = azurerm.firewall
  subnet_id                 = azurerm_subnet.mgmt.id
  network_security_group_id = azurerm_network_security_group.mgmt_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "public_assoc" {
  provider                  = azurerm.firewall
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.public_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "private_assoc" {
  provider                  = azurerm.firewall
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.private_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "twingate_assoc" {
  provider                  = azurerm.firewall
  subnet_id                 = azurerm_subnet.twingate.id
  network_security_group_id = azurerm_network_security_group.twingate_nsg.id
}









