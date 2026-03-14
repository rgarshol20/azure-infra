module "cgiadsazp01" {
  source = "../modules/windows-server"
  providers = {
    azurerm = azurerm.prod
  }

  name                = "CGIADSAZP01"
  nic_name            = "cgiadsazp01-nic"
  location            = azurerm_resource_group.servers.location
  resource_group_name = azurerm_resource_group.servers.name
  size                = "Standard_E8-4s_v3"
  admin_username      = "test-admin"
  admin_password      = module.key_vault.admin_password_value
  subnet_id           = azurerm_subnet.servers.id
  private_ip_address  = "10.20.1.12"

  source_image_id = data.azurerm_image.win2022_ads_image.id

  encryption_at_host_enabled = true
  disk_encryption_set_id     = module.key_vault.des_id
  secure_boot_enabled        = false
  vtpm_enabled               = false

  os_disk_size_gb = 127

  patch_mode            = "AutomaticByOS"
  patch_assessment_mode = "AutomaticByPlatform"

  data_disks = [
    {
      name                 = "cgiadsazp01-compliancedisk"
      disk_size_gb         = 2500
      lun                  = 0
      caching              = "ReadWrite"
      storage_account_type = "Premium_LRS"
    },
    {
      name                 = "cgiadsazp01-demodisk"
      disk_size_gb         = 2500
      lun                  = 1
      caching              = "ReadWrite"
      storage_account_type = "Premium_LRS"
    }
  ]

  tags = local.required_tags
}

moved {
  from = azurerm_network_interface.nic_cgiadsazp01
  to   = module.cgiadsazp01.azurerm_network_interface.this
}

moved {
  from = azurerm_windows_virtual_machine.cgiadsazp01_vm
  to   = module.cgiadsazp01.azurerm_windows_virtual_machine.this
}

moved {
  from = azurerm_virtual_machine_extension.cgiadsazp01_guestconfig
  to   = module.cgiadsazp01.azurerm_virtual_machine_extension.policy
}

moved {
  from = azurerm_managed_disk.cgiadsazp01_compliance_disk
  to   = module.cgiadsazp01.azurerm_managed_disk.data[0]
}

moved {
  from = azurerm_virtual_machine_data_disk_attachment.cgiadsazp01_attach_compliance
  to   = module.cgiadsazp01.azurerm_virtual_machine_data_disk_attachment.data[0]
}

moved {
  from = azurerm_managed_disk.cgiadsazp01_demo_disk
  to   = module.cgiadsazp01.azurerm_managed_disk.data[1]
}

moved {
  from = azurerm_virtual_machine_data_disk_attachment.cgiadsazp01_attach_demo
  to   = module.cgiadsazp01.azurerm_virtual_machine_data_disk_attachment.data[1]
}

resource "azurerm_monitor_data_collection_rule_association" "cgiadsazp01_dcr_association" {
  provider                = azurerm.prod
  name                    = "cgiadsazp01-vm-dcr-association"
  target_resource_id      = module.cgiadsazp01.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.windows_dcr.id
}

resource "azurerm_backup_protected_vm" "cgiadsazp01_vm" {
  provider            = azurerm.prod
  resource_group_name = azurerm_resource_group.backup.name
  recovery_vault_name = module.recovery_vault.vault_name
  source_vm_id        = module.cgiadsazp01.id
  backup_policy_id    = module.recovery_vault.backup_policy_ids["AcmeHealthProd"]
}
