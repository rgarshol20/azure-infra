resource "azurerm_public_ip" "mgmtsvcs_pip" {
  provider            = azurerm.firewall
  name                = "pip-acme-health-svcsvnet-westus-mgmt2"
  location            = azurerm_resource_group.firewall.location
  resource_group_name = azurerm_resource_group.firewall.name
  allocation_method   = "Static"
  sku                 = "Basic"
  domain_name_label   = "acme-health-svcs" # <-- add this so there is no diff

  tags = local.required_tags
}

resource "azurerm_network_interface" "firewall_nic_mgmt" {
  #checkov:skip=CKV_AZURE_119:Public IP required for firewall management access; traffic controlled by NSG and Palo Alto ACLs
  provider            = azurerm.firewall
  name                = "acme-health-fw-mgmt-nic"
  location            = azurerm_resource_group.firewall.location
  resource_group_name = azurerm_resource_group.firewall.name

  ip_configuration {
    name                          = "firewall-ipconfig-mgmt"
    subnet_id                     = azurerm_subnet.mgmt.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.99.0.4"
    public_ip_address_id          = azurerm_public_ip.mgmtsvcs_pip.id
  }

  tags = local.required_tags
}

resource "azurerm_public_ip" "acme-health-svcs_pip" {
  name                = "AcmeHealthSvcsPublicIP"
  location            = azurerm_resource_group.firewall.location
  resource_group_name = azurerm_resource_group.firewall.name
  allocation_method   = "Static"
  sku                 = "Basic" # matches what you provided

  tags = local.required_tags
}

resource "azurerm_network_interface" "firewall_nic_public" {
  #checkov:skip=CKV_AZURE_119:Public IP required for firewall public interface; traffic controlled by NSG and Palo Alto ACLs
  provider            = azurerm.firewall
  name                = "acme-health-fw-public-nic"
  location            = azurerm_resource_group.firewall.location
  resource_group_name = azurerm_resource_group.firewall.name

  ip_configuration {
    name                          = "firewall-ipconfig-public"
    subnet_id                     = azurerm_subnet.public.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.99.1.4"
    # Correct method to reference the public IP ID in the latest provider versions
    public_ip_address_id = azurerm_public_ip.acme-health-svcs_pip.id
  }

  ip_forwarding_enabled = true # ✅ Ensure IP Forwarding remains enabled
  tags                  = local.required_tags
}

resource "azurerm_network_interface" "firewall_nic_private" {
  provider            = azurerm.firewall
  name                = "acme-health-fw-private-nic"
  location            = azurerm_resource_group.firewall.location
  resource_group_name = azurerm_resource_group.firewall.name

  ip_configuration {
    name                          = "firewall-ipconfig-private"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.99.2.4"
  }
  ip_forwarding_enabled = true # ✅ Ensure IP Forwarding remains enabled
  tags                  = local.required_tags
}

# VM and NICs
resource "azurerm_linux_virtual_machine" "firewall" {
  #checkov:skip=CKV_AZURE_1:Palo Alto vmseries-flex requires password auth; SSH keys not supported by appliance
  #checkov:skip=CKV_AZURE_149:Palo Alto vmseries-flex requires password auth; SSH keys not supported by appliance
  #checkov:skip=CKV_AZURE_178:Palo Alto vmseries-flex requires password auth; SSH keys not supported by appliance
  #checkov:skip=CKV_AZURE_50:Palo Alto marketplace image; Azure VM extensions not applicable
  provider            = azurerm.firewall
  name                = "ACME-HEALTH-SVCS-FW"
  resource_group_name = azurerm_resource_group.firewall.name
  location            = azurerm_resource_group.firewall.location
  size                = "Standard_D3_v2"

  network_interface_ids = [
    azurerm_network_interface.firewall_nic_mgmt.id, azurerm_network_interface.firewall_nic_public.id, azurerm_network_interface.firewall_nic_private.id
  ]

  identity {
    type = "SystemAssigned"
  }

  # RISK ACCEPTANCE: admin_username cannot be changed without VM recreation (destructive)
  admin_username                  = "test-admin"
  disable_password_authentication = false
  admin_password                  = var.admin_password

  os_disk {
    name                   = "acme-health-fw-osdisk"
    caching                = "ReadWrite"
    storage_account_type   = "Standard_LRS"
    disk_encryption_set_id = module.key_vault.des_id
  }
  source_image_reference {
    publisher = "paloaltonetworks"
    offer     = "vmseries-flex"
    sku       = "byol"
    version   = "latest"
  }

  plan {
    name      = "byol"
    product   = "vmseries-flex"
    publisher = "paloaltonetworks"
  }

  # RISK ACCEPTANCE: encryption_at_host_enabled not set — Palo Alto vmseries-flex BYOL
  # marketplace image does not support host encryption; disk encryption via DES is applied.
  tags = local.required_tags
}
# resource "azurerm_subnet_route_table_association" "dmz_assoc" {
#   provider                  = azurerm.firewall
#   subnet_id      = azurerm_subnet.dmz.id
#   route_table_id = azurerm_route_table.dmz_rt.id
# }
