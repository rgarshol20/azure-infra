module "bizarcazp01" {
  source = "../modules/windows-server"
  providers = {
    azurerm = azurerm.prod
  }

  name                = "BIZARCAZP01"
  nic_name            = "bizarcazp01-nic"
  location            = azurerm_resource_group.servers.location
  resource_group_name = azurerm_resource_group.servers.name
  size                = "Standard_E4s_v3"
  admin_username      = "test-admin"
  admin_password      = module.key_vault.admin_password_value
  subnet_id           = azurerm_subnet.servers.id
  private_ip_address  = "10.20.1.15"

  source_image_id = data.azurerm_image.win2022_ads_image.id

  encryption_at_host_enabled = true
  disk_encryption_set_id     = module.key_vault.des_id
  secure_boot_enabled        = false
  vtpm_enabled               = false

  os_disk_size_gb = 127

  patch_mode            = "AutomaticByOS"
  patch_assessment_mode = "AutomaticByPlatform"

  data_disks = [{
    name                 = "bizarcazp01-datadisk"
    disk_size_gb         = 2000
    lun                  = 0
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }]

  tags = local.required_tags
}

moved {
  from = azurerm_network_interface.nic_bizarcazp01
  to   = module.bizarcazp01.azurerm_network_interface.this
}

moved {
  from = azurerm_windows_virtual_machine.bizarcazp01_vm
  to   = module.bizarcazp01.azurerm_windows_virtual_machine.this
}

moved {
  from = azurerm_virtual_machine_extension.bizarcazp01_guestconfig
  to   = module.bizarcazp01.azurerm_virtual_machine_extension.policy
}

moved {
  from = azurerm_managed_disk.bizarcazp01_data_disk
  to   = module.bizarcazp01.azurerm_managed_disk.data[0]
}

moved {
  from = azurerm_virtual_machine_data_disk_attachment.bizarcazp01_attach_data
  to   = module.bizarcazp01.azurerm_virtual_machine_data_disk_attachment.data[0]
}

resource "azurerm_monitor_data_collection_rule_association" "bizarcazp01_dcr_association" {
  provider                = azurerm.prod
  name                    = "bizarcazp01-vm-dcr-association"
  target_resource_id      = module.bizarcazp01.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.windows_dcr.id
}

resource "azurerm_backup_protected_vm" "bizarcazp01_vm" {
  provider            = azurerm.prod
  resource_group_name = azurerm_resource_group.backup.name
  recovery_vault_name = module.recovery_vault.vault_name
  source_vm_id        = module.bizarcazp01.id
  backup_policy_id    = module.recovery_vault.backup_policy_ids["AcmeHealthProd"]
}
