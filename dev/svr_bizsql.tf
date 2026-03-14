module "bizsqlazt01" {
  source = "../modules/windows-server"
  providers = {
    azurerm = azurerm.dev
  }

  name                = "bizsqlazt01"
  nic_name            = "bizsqlazt01-nic"
  location            = azurerm_resource_group.servers.location
  resource_group_name = azurerm_resource_group.servers.name
  size                = "Standard_E4s_v3"
  admin_username      = "test-admin"
  admin_password      = module.key_vault.admin_password_value
  subnet_id           = azurerm_subnet.servers.id
  private_ip_address  = "10.30.1.16"

  source_image_id = data.azurerm_image.win2022_mysql_image.id

  encryption_at_host_enabled = true
  disk_encryption_set_id     = module.key_vault.des_id
  secure_boot_enabled        = false
  vtpm_enabled               = false

  os_disk_size_gb = 250

  patch_mode            = "AutomaticByOS"
  patch_assessment_mode = "AutomaticByPlatform"

  data_disks = [{
    name                 = "bizsqlazt01-datadisk"
    disk_size_gb         = 500
    lun                  = 0
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }]

  tags = local.required_tags
}

moved {
  from = azurerm_network_interface.nic_bizsqlazt01
  to   = module.bizsqlazt01.azurerm_network_interface.this
}

moved {
  from = azurerm_windows_virtual_machine.bizsqlazt01_vm
  to   = module.bizsqlazt01.azurerm_windows_virtual_machine.this
}

moved {
  from = azurerm_virtual_machine_extension.bizsqlazt01_guestconfig
  to   = module.bizsqlazt01.azurerm_virtual_machine_extension.policy
}

moved {
  from = azurerm_managed_disk.bizsqlazt01_data_disk
  to   = module.bizsqlazt01.azurerm_managed_disk.data[0]
}

moved {
  from = azurerm_virtual_machine_data_disk_attachment.bizsqlazt01_attach_data
  to   = module.bizsqlazt01.azurerm_virtual_machine_data_disk_attachment.data[0]
}

resource "azurerm_monitor_data_collection_rule_association" "bizsqlazt01_dcr_association" {
  provider                = azurerm.dev
  name                    = "bizsqlazt01-vm-dcr-association"
  target_resource_id      = module.bizsqlazt01.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.windows_dcr.id
}

resource "azurerm_backup_protected_vm" "bizsqlazt01_vm" {
  provider            = azurerm.dev
  resource_group_name = azurerm_resource_group.backup.name
  recovery_vault_name = module.recovery_vault.vault_name
  source_vm_id        = module.bizsqlazt01.id
  backup_policy_id    = module.recovery_vault.backup_policy_ids["acme_health_dev_v2"]
}
