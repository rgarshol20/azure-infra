########################################
# Variables / locals
########################################

# How many worker VMs to create (two-digit numbering)
variable "bizwrkazp_count" {
  type        = number
  description = "Number of BIZWRKAZP workers to create (e.g., 1..99)."
  default     = 09
}

locals {
  # Keys will be "01", "02", ..., "NN"
  bizwrkazp_ids = [
    for i in range(var.bizwrkazp_count) : format("%02d", i + 1)
  ]
}

########################################
# Module (replaces raw NIC + VM + extension)
########################################

module "bizwrkazp" {
  source   = "../modules/windows-server"
  for_each = toset(local.bizwrkazp_ids)
  providers = {
    azurerm = azurerm.prod
  }

  name                = "BIZWRKAZP${each.key}"
  nic_name            = "bizwrkazp${each.key}-nic"
  location            = azurerm_resource_group.workers.location
  resource_group_name = azurerm_resource_group.workers.name
  size                = "Standard_D8ads_v5"
  admin_username      = "test-admin"
  admin_password      = module.key_vault.admin_password_value
  subnet_id           = azurerm_subnet.workers.id
  private_ip_address  = "10.20.2.${tonumber(each.key) + 10}"

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

########################################
# Moved blocks — NICs
########################################

moved {
  from = azurerm_network_interface.nic_bizwrkazp["01"]
  to   = module.bizwrkazp["01"].azurerm_network_interface.this
}
moved {
  from = azurerm_network_interface.nic_bizwrkazp["02"]
  to   = module.bizwrkazp["02"].azurerm_network_interface.this
}
moved {
  from = azurerm_network_interface.nic_bizwrkazp["03"]
  to   = module.bizwrkazp["03"].azurerm_network_interface.this
}
moved {
  from = azurerm_network_interface.nic_bizwrkazp["04"]
  to   = module.bizwrkazp["04"].azurerm_network_interface.this
}
moved {
  from = azurerm_network_interface.nic_bizwrkazp["05"]
  to   = module.bizwrkazp["05"].azurerm_network_interface.this
}
moved {
  from = azurerm_network_interface.nic_bizwrkazp["06"]
  to   = module.bizwrkazp["06"].azurerm_network_interface.this
}
moved {
  from = azurerm_network_interface.nic_bizwrkazp["07"]
  to   = module.bizwrkazp["07"].azurerm_network_interface.this
}
moved {
  from = azurerm_network_interface.nic_bizwrkazp["08"]
  to   = module.bizwrkazp["08"].azurerm_network_interface.this
}
moved {
  from = azurerm_network_interface.nic_bizwrkazp["09"]
  to   = module.bizwrkazp["09"].azurerm_network_interface.this
}

########################################
# Moved blocks — VMs
########################################

moved {
  from = azurerm_windows_virtual_machine.bizwrkazp_vm["01"]
  to   = module.bizwrkazp["01"].azurerm_windows_virtual_machine.this
}
moved {
  from = azurerm_windows_virtual_machine.bizwrkazp_vm["02"]
  to   = module.bizwrkazp["02"].azurerm_windows_virtual_machine.this
}
moved {
  from = azurerm_windows_virtual_machine.bizwrkazp_vm["03"]
  to   = module.bizwrkazp["03"].azurerm_windows_virtual_machine.this
}
moved {
  from = azurerm_windows_virtual_machine.bizwrkazp_vm["04"]
  to   = module.bizwrkazp["04"].azurerm_windows_virtual_machine.this
}
moved {
  from = azurerm_windows_virtual_machine.bizwrkazp_vm["05"]
  to   = module.bizwrkazp["05"].azurerm_windows_virtual_machine.this
}
moved {
  from = azurerm_windows_virtual_machine.bizwrkazp_vm["06"]
  to   = module.bizwrkazp["06"].azurerm_windows_virtual_machine.this
}
moved {
  from = azurerm_windows_virtual_machine.bizwrkazp_vm["07"]
  to   = module.bizwrkazp["07"].azurerm_windows_virtual_machine.this
}
moved {
  from = azurerm_windows_virtual_machine.bizwrkazp_vm["08"]
  to   = module.bizwrkazp["08"].azurerm_windows_virtual_machine.this
}
moved {
  from = azurerm_windows_virtual_machine.bizwrkazp_vm["09"]
  to   = module.bizwrkazp["09"].azurerm_windows_virtual_machine.this
}

########################################
# Moved blocks — Guest config extensions
########################################

moved {
  from = azurerm_virtual_machine_extension.bizwrkazp_guestconfig["01"]
  to   = module.bizwrkazp["01"].azurerm_virtual_machine_extension.policy
}
moved {
  from = azurerm_virtual_machine_extension.bizwrkazp_guestconfig["02"]
  to   = module.bizwrkazp["02"].azurerm_virtual_machine_extension.policy
}
moved {
  from = azurerm_virtual_machine_extension.bizwrkazp_guestconfig["03"]
  to   = module.bizwrkazp["03"].azurerm_virtual_machine_extension.policy
}
moved {
  from = azurerm_virtual_machine_extension.bizwrkazp_guestconfig["04"]
  to   = module.bizwrkazp["04"].azurerm_virtual_machine_extension.policy
}
moved {
  from = azurerm_virtual_machine_extension.bizwrkazp_guestconfig["05"]
  to   = module.bizwrkazp["05"].azurerm_virtual_machine_extension.policy
}
moved {
  from = azurerm_virtual_machine_extension.bizwrkazp_guestconfig["06"]
  to   = module.bizwrkazp["06"].azurerm_virtual_machine_extension.policy
}
moved {
  from = azurerm_virtual_machine_extension.bizwrkazp_guestconfig["07"]
  to   = module.bizwrkazp["07"].azurerm_virtual_machine_extension.policy
}
moved {
  from = azurerm_virtual_machine_extension.bizwrkazp_guestconfig["08"]
  to   = module.bizwrkazp["08"].azurerm_virtual_machine_extension.policy
}
moved {
  from = azurerm_virtual_machine_extension.bizwrkazp_guestconfig["09"]
  to   = module.bizwrkazp["09"].azurerm_virtual_machine_extension.policy
}

########################################
# DCR association
########################################

resource "azurerm_monitor_data_collection_rule_association" "bizwrkazp_dcr_association" {
  provider = azurerm.prod
  for_each = module.bizwrkazp

  name                    = "bizwrkazp${each.key}-vm-dcr-association"
  target_resource_id      = each.value.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.windows_dcr.id
}

########################################
# Backup protection
########################################

resource "azurerm_backup_protected_vm" "bizwrkazp_vm" {
  provider = azurerm.prod
  for_each = module.bizwrkazp

  resource_group_name = azurerm_resource_group.backup.name
  recovery_vault_name = module.recovery_vault.vault_name
  source_vm_id        = each.value.id
  backup_policy_id    = module.recovery_vault.backup_policy_ids["AcmeHealthProd"]
}
