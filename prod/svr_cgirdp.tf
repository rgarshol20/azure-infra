module "cgirdpazp01" {
  source = "../modules/windows-server"
  providers = {
    azurerm = azurerm.prod
  }

  name                = "CGIRDPAZP01"
  nic_name            = "cgirdpazp01-nic"
  location            = azurerm_resource_group.workers.location
  resource_group_name = azurerm_resource_group.workers.name
  size                = "Standard_E16s_v3"
  admin_username      = "test-admin"
  admin_password      = module.key_vault.admin_password_value
  subnet_id           = azurerm_subnet.workers.id
  private_ip_address  = "10.20.2.10"

  source_image_id = data.azurerm_image.imageBIZWRKZAP.id

  encryption_at_host_enabled = true
  disk_encryption_set_id     = module.key_vault.des_id
  secure_boot_enabled        = false
  vtpm_enabled               = false

  os_disk_size_gb = 1024

  patch_mode            = "AutomaticByOS"
  patch_assessment_mode = "AutomaticByPlatform"

  tags = local.required_tags
}

moved {
  from = azurerm_network_interface.nic_cgirdpazp01
  to   = module.cgirdpazp01.azurerm_network_interface.this
}

moved {
  from = azurerm_windows_virtual_machine.cgirdpazp01_vm
  to   = module.cgirdpazp01.azurerm_windows_virtual_machine.this
}

moved {
  from = azurerm_virtual_machine_extension.cgirdpazp01_guestconfig
  to   = module.cgirdpazp01.azurerm_virtual_machine_extension.policy
}

resource "azurerm_monitor_data_collection_rule_association" "cgirdpazp01_dcr_association" {
  provider                = azurerm.prod
  name                    = "cgirdpazp01-vm-dcr-association"
  target_resource_id      = module.cgirdpazp01.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.windows_dcr.id
}

resource "azurerm_backup_protected_vm" "cgirdpazp01_vm" {
  provider            = azurerm.prod
  resource_group_name = azurerm_resource_group.backup.name
  recovery_vault_name = module.recovery_vault.vault_name
  source_vm_id        = module.cgirdpazp01.id
  backup_policy_id    = module.recovery_vault.backup_policy_ids["AcmeHealthProd"]
}
