resource "azurerm_public_ip" "panorama_public_ip" {
  provider            = azurerm.firewall
  name                = "panorama-pip"
  location            = azurerm_resource_group.firewall.location
  resource_group_name = azurerm_resource_group.firewall.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.required_tags
}

# Panorama NIC
resource "azurerm_network_interface" "panorama_nic" {
  #checkov:skip=CKV_AZURE_119:Public IP required for Panorama management access; traffic controlled by NSG and Palo Alto ACLs
  provider            = azurerm.firewall
  name                = "panorama-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.firewall.name # Reference the correct resource group

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.mgmt.id
    private_ip_address            = "10.99.0.5" # Hardcoded static IP
    private_ip_address_allocation = "Static"
    public_ip_address_id          = azurerm_public_ip.panorama_public_ip.id
  }

  tags = local.required_tags
}

# Panorama VM
resource "azurerm_linux_virtual_machine" "panorama" {
  #checkov:skip=CKV_AZURE_1:Palo Alto Panorama requires password auth; SSH keys not supported by appliance
  #checkov:skip=CKV_AZURE_149:Palo Alto Panorama requires password auth; SSH keys not supported by appliance
  #checkov:skip=CKV_AZURE_178:Palo Alto Panorama requires password auth; SSH keys not supported by appliance
  #checkov:skip=CKV_AZURE_50:Palo Alto marketplace image; Azure VM extensions not applicable
  provider              = azurerm.firewall
  name                  = "ACME-HEALTH-SVCS-PANORAMA"
  resource_group_name   = azurerm_resource_group.firewall.name
  location              = azurerm_resource_group.firewall.location
  size                  = "Standard_D4_v3"
  network_interface_ids = [azurerm_network_interface.panorama_nic.id]

  identity {
    type = "SystemAssigned"
  }

  # RISK ACCEPTANCE: admin_username cannot be changed without VM recreation (destructive)
  admin_username                  = "test-admin"
  disable_password_authentication = false
  admin_password                  = var.admin_password # Use a variable for the password

  os_disk {
    name                   = "panorama-osdisk"
    caching                = "ReadWrite"
    storage_account_type   = "Standard_LRS"
    disk_encryption_set_id = module.key_vault.des_id
  }

  source_image_reference {
    publisher = "paloaltonetworks"
    offer     = "panorama"
    sku       = "byol"
    version   = "12.1.2"
  }

  plan {
    publisher = "paloaltonetworks"
    product   = "panorama"
    name      = "byol"
  }

  # RISK ACCEPTANCE: encryption_at_host_enabled not set — Palo Alto panorama BYOL
  # marketplace image does not support host encryption; disk encryption via DES is applied.
  tags = local.required_tags
}

