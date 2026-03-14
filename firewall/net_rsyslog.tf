resource "azurerm_network_interface" "nic_syslog" {
  provider            = azurerm.firewall
  name                = "nic-syslog"
  location            = var.location
  resource_group_name = azurerm_resource_group.firewall.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.99.2.5" # adjust as needed
  }
}

resource "azurerm_linux_virtual_machine" "syslog_vm" {
  #checkov:skip=CKV_AZURE_1:Syslog relay uses password auth; switching to SSH keys requires VM recreation (maintenance window needed)
  #checkov:skip=CKV_AZURE_149:Syslog relay uses password auth; switching to SSH keys requires VM recreation (maintenance window needed)
  #checkov:skip=CKV_AZURE_178:Syslog relay uses password auth; switching to SSH keys requires VM recreation (maintenance window needed)
  #checkov:skip=CKV_AZURE_50:AzureMonitorLinuxAgent extension installed by design for syslog collection
  provider            = azurerm.firewall
  name                = "syslog-vm"
  location            = var.location
  resource_group_name = azurerm_resource_group.firewall.name
  network_interface_ids = [
    azurerm_network_interface.nic_syslog.id,
  ]
  size                       = "Standard_B1ms"
  encryption_at_host_enabled = true
  # RISK ACCEPTANCE: admin_username cannot be changed without VM recreation (destructive)
  admin_username                  = var.syslog_username
  admin_password                  = var.syslog_password
  disable_password_authentication = false

  os_disk {
    caching                = "ReadWrite"
    storage_account_type   = "Premium_LRS"
    disk_encryption_set_id = module.key_vault.des_id
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Use Azure’s platform-managed patching
  patch_mode            = "AutomaticByPlatform"
  patch_assessment_mode = "AutomaticByPlatform"

  identity {
    type = "SystemAssigned"
  }

  tags = local.required_tags
}

# AMA Extension
resource "azurerm_virtual_machine_extension" "ama_extension" {
  provider                   = azurerm.firewall
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.syslog_vm.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
}

resource "azurerm_monitor_data_collection_rule_association" "syslog_vm_assoc" {
  provider                = azurerm.firewall
  name                    = "assoc-syslog-vm"
  target_resource_id      = azurerm_linux_virtual_machine.syslog_vm.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.syslog_dcr.id
}
