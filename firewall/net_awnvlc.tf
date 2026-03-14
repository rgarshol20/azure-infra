############################
# NIC for VLC
############################

resource "azurerm_network_interface" "aw_vlc_nic" {
  provider            = azurerm.firewall
  name                = "arcticwolfvlc-nic"
  location            = azurerm_resource_group.firewall.location
  resource_group_name = azurerm_resource_group.firewall.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.99.2.11" # must be free and inside that subnet’s CIDR
  }
}

############################
# Arctic Wolf VLC VM
############################

resource "azurerm_linux_virtual_machine" "aw_vlc" {
  #checkov:skip=CKV_AZURE_1:Arctic Wolf VLC vendor appliance requires password auth; SSH keys not supported
  #checkov:skip=CKV_AZURE_149:Arctic Wolf VLC vendor appliance requires password auth; SSH keys not supported
  #checkov:skip=CKV_AZURE_178:Arctic Wolf VLC vendor appliance requires password auth; SSH keys not supported
  #checkov:skip=CKV_AZURE_50:Vendor appliance marketplace image; Azure VM extensions not applicable
  provider                   = azurerm.firewall
  name                       = "arcticwolfvlc"
  location                   = azurerm_resource_group.firewall.location
  resource_group_name        = azurerm_resource_group.firewall.name
  size                       = "Standard_D2as_v5"
  encryption_at_host_enabled = true

  network_interface_ids = [
    azurerm_network_interface.aw_vlc_nic.id,
  ]

  # Local login via username/password
  disable_password_authentication = false
  # RISK ACCEPTANCE: admin_username cannot be changed without VM recreation (destructive)
  admin_username = var.syslog_username
  admin_password = var.syslog_password

  os_disk {
    name                   = "vlc-core-logging-01-osdisk"
    caching                = "ReadWrite"
    storage_account_type   = "Premium_LRS"
    disk_encryption_set_id = module.key_vault.des_id
  }

  boot_diagnostics {}
  identity {
    type = "SystemAssigned"
  }

  # Image details from az vm show
  source_image_reference {
    publisher = "arcticwolfnetworks1680048607525"
    offer     = "awn-virtual-appliance"
    sku       = "awn-virtual-appliance"
    version   = "0.47.2942"
    # version = "latest"  # optional alternative
  }

  # Required Marketplace plan block
  plan {
    publisher = "arcticwolfnetworks1680048607525"
    product   = "awn-virtual-appliance"
    name      = "awn-virtual-appliance"
  }

  tags = local.required_tags
}

resource "azurerm_monitor_data_collection_rule_association" "aw_vlc_dcr_association" {
  provider                = azurerm.firewall
  name                    = "arcticwolfvlc-dcr-association"
  target_resource_id      = azurerm_linux_virtual_machine.aw_vlc.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.syslog_dcr.id
}
