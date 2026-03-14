module "actdirazp01" {
  source = "../modules/windows-server"
  providers = {
    azurerm = azurerm.identity
  }

  name                = "ACTDIRAZP01"
  location            = azurerm_resource_group.ad.location
  resource_group_name = azurerm_resource_group.ad.name
  size                = "Standard_B2ms"
  admin_username      = "test-admin"
  admin_password      = module.key_vault.admin_password_value
  nic_name            = "actdirazp01-nic"
  subnet_id           = azurerm_subnet.ad.id
  private_ip_address  = "10.10.1.10"

  encryption_at_host_enabled = true
  disk_encryption_set_id     = module.key_vault.des_id
  secure_boot_enabled        = false
  vtpm_enabled               = false

  os_disk_size_gb = 200

  source_image_publisher = "MicrosoftWindowsServer"
  source_image_offer     = "WindowsServer"
  source_image_sku       = "2022-datacenter"
  source_image_version   = "latest"

  patch_mode            = "AutomaticByOS"
  patch_assessment_mode = "AutomaticByPlatform"

  tags = local.required_tags
}

moved {
  from = azurerm_network_interface.nic_actdirazp01
  to   = module.actdirazp01.azurerm_network_interface.this
}

moved {
  from = azurerm_windows_virtual_machine.actdirazp01_vm
  to   = module.actdirazp01.azurerm_windows_virtual_machine.this
}

moved {
  from = azurerm_virtual_machine_extension.actdirazp01_guestconfig
  to   = module.actdirazp01.azurerm_virtual_machine_extension.policy
}

resource "azurerm_monitor_data_collection_rule_association" "actdirazp01_dcr_association" {
  provider                = azurerm.identity
  name                    = "actdirazp01-vm-dcr-association"
  target_resource_id      = module.actdirazp01.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.windows_dcr.id
}

resource "azurerm_backup_protected_vm" "actdirazp01_vm" {
  provider            = azurerm.identity
  resource_group_name = azurerm_resource_group.backup.name
  recovery_vault_name = module.recovery_vault.vault_name
  source_vm_id        = module.actdirazp01.id
  backup_policy_id    = module.recovery_vault.backup_policy_ids["AcmeHealthID"]

  lifecycle {
    ignore_changes = [backup_policy_id]
  }
}
