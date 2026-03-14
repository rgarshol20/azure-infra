# Network Interface
resource "azurerm_network_interface" "this" {
  name                           = var.nic_name != null ? var.nic_name : "${var.name}-nic"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  accelerated_networking_enabled = var.accelerated_networking_enabled

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_address != null ? "Static" : "Dynamic"
    private_ip_address            = var.private_ip_address
  }

  tags = var.tags
}

# NSG Association (optional)
resource "azurerm_network_interface_security_group_association" "this" {
  count                     = var.network_security_group_id != null ? 1 : 0
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = var.network_security_group_id
}

# Windows Virtual Machine
resource "azurerm_windows_virtual_machine" "this" {
  #checkov:skip=CKV_AZURE_50:GuestConfiguration extension installed by design for Azure Policy compliance
  name                       = var.name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  size                       = var.size
  admin_username             = var.admin_username
  admin_password             = var.admin_password
  network_interface_ids      = [azurerm_network_interface.this.id]
  zone                       = var.zone
  secure_boot_enabled        = var.secure_boot_enabled
  vtpm_enabled               = var.vtpm_enabled
  encryption_at_host_enabled = var.encryption_at_host_enabled
  provision_vm_agent         = true
  patch_mode                             = var.patch_mode
  patch_assessment_mode                  = var.patch_assessment_mode
  vm_agent_platform_updates_enabled      = var.patch_assessment_mode == "AutomaticByPlatform" ? true : null

  os_disk {
    caching                = var.os_disk_caching
    storage_account_type   = var.os_disk_storage_account_type
    disk_size_gb           = var.os_disk_size_gb
    disk_encryption_set_id = var.disk_encryption_set_id
  }

  # Use source_image_id if provided (for custom images), otherwise use source_image_reference
  source_image_id = var.source_image_id

  dynamic "source_image_reference" {
    for_each = var.source_image_id == null ? [1] : []
    content {
      publisher = var.source_image_publisher
      offer     = var.source_image_offer
      sku       = var.source_image_sku
      version   = var.source_image_version
    }
  }

  identity {
    type = "SystemAssigned"
  }

  boot_diagnostics {
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [vm_agent_platform_updates_enabled]
  }
}

# Azure Policy Guest Configuration Extension
resource "azurerm_virtual_machine_extension" "policy" {
  name                       = "AzurePolicyforWindows"
  virtual_machine_id         = azurerm_windows_virtual_machine.this.id
  publisher                  = "Microsoft.GuestConfiguration"
  type                       = "ConfigurationforWindows"
  type_handler_version       = "1.1"
  auto_upgrade_minor_version = true
  settings                   = jsonencode({})

  depends_on = [azurerm_windows_virtual_machine.this]

  lifecycle {
    ignore_changes = all
  }
}

# Data Collection Rule Association (optional)
resource "azurerm_monitor_data_collection_rule_association" "this" {
  count                   = var.data_collection_rule_id != null ? 1 : 0
  name                    = "${var.name}-dcr-association"
  target_resource_id      = azurerm_windows_virtual_machine.this.id
  data_collection_rule_id = var.data_collection_rule_id

  depends_on = [azurerm_windows_virtual_machine.this]
}

# Backup Protection (optional)
resource "azurerm_backup_protected_vm" "this" {
  count               = var.recovery_vault_id != null && var.backup_policy_id != null ? 1 : 0
  resource_group_name = var.backup_resource_group_name != null ? var.backup_resource_group_name : var.resource_group_name
  recovery_vault_name = split("/", var.recovery_vault_id)[8]
  source_vm_id        = azurerm_windows_virtual_machine.this.id
  backup_policy_id    = var.backup_policy_id

  depends_on = [azurerm_windows_virtual_machine.this]
}

# Data Disks
resource "azurerm_managed_disk" "data" {
  #checkov:skip=CKV_AZURE_251:Data disks accessed exclusively via VM; no independent network exposure
  count                  = length(var.data_disks)
  name                   = var.data_disks[count.index].name
  location               = var.location
  resource_group_name    = var.resource_group_name
  storage_account_type   = var.data_disks[count.index].storage_account_type
  create_option          = "Empty"
  disk_size_gb           = var.data_disks[count.index].disk_size_gb
  disk_encryption_set_id = var.disk_encryption_set_id
  zone                   = var.zone

  tags = var.tags
}

# Data Disk Attachments
resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  count              = length(var.data_disks)
  managed_disk_id    = azurerm_managed_disk.data[count.index].id
  virtual_machine_id = azurerm_windows_virtual_machine.this.id
  lun                = var.data_disks[count.index].lun
  caching            = var.data_disks[count.index].caching

  depends_on = [azurerm_windows_virtual_machine.this, azurerm_managed_disk.data]
}
