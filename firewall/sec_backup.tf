# (A) Recovery Services Vault

module "recovery_vault" {
  source = "../modules/recovery-vault"
  providers = {
    azurerm = azurerm.firewall
  }

  vault_name          = "rsv-core-firewall"
  location            = azurerm_resource_group.logging.location
  resource_group_name = azurerm_resource_group.logging.name

  soft_delete_enabled = true
  immutability        = "Unlocked"

  vm_backup_policies = [
    {
      name                       = "acme_health_firewall"
      backup_frequency           = "Daily"
      backup_time                = "02:00"
      timezone                   = "UTC"
      retention_daily_count      = 30
      retention_weekly_count     = 12
      retention_weekly_weekdays  = ["Sunday"]
      retention_monthly_count    = 12
      retention_monthly_weekdays = ["Sunday"]
      retention_monthly_weeks    = ["First"]
    }
  ]

  tags = local.required_tags
}

moved {
  from = azurerm_recovery_services_vault.rsv
  to   = module.recovery_vault.azurerm_recovery_services_vault.this
}

moved {
  from = azurerm_backup_policy_vm.acme_health_firewall
  to   = module.recovery_vault.azurerm_backup_policy_vm.vm_policies["acme_health_firewall"]
}

# (B) VM Backup Protection

# azurerm_backup_protected_vm.firewall_vm removed — Palo Alto VM-Series does not
# support Azure Backup (no Guest Agent / VSS). Use PAN-OS config export instead.

resource "azurerm_backup_protected_vm" "syslog_vm" {
  provider            = azurerm.firewall
  resource_group_name = azurerm_resource_group.logging.name
  recovery_vault_name = module.recovery_vault.vault_name
  source_vm_id        = azurerm_linux_virtual_machine.syslog_vm.id
  backup_policy_id    = module.recovery_vault.backup_policy_ids["acme_health_firewall"]
}

resource "azurerm_backup_protected_vm" "aw_vlc_vm" {
  provider            = azurerm.firewall
  resource_group_name = azurerm_resource_group.logging.name
  recovery_vault_name = module.recovery_vault.vault_name
  source_vm_id        = azurerm_linux_virtual_machine.aw_vlc.id
  backup_policy_id    = module.recovery_vault.backup_policy_ids["acme_health_firewall"]
}

# azurerm_backup_protected_vm.panorama_vm removed — Panorama does not support
# Azure Backup. Use Panorama device state export for configuration backup.

# Diagnostic settings for Recovery Services Vault (HIPAA audit trail)
module "diag_rsv_firewall" {
  source = "../modules/diagnostic-settings"

  diagnostic_setting_name    = "diag-rsv-firewall"
  target_resource_id         = module.recovery_vault.vault_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.local_law.id
  storage_account_id         = module.remote_state.logging.outputs.archive_storage_account_id

  log_categories = [
    "CoreAzureBackup",
    "AddonAzureBackupJobs",
    "AddonAzureBackupPolicy",
    "AddonAzureBackupStorage",
    "AddonAzureBackupProtectedInstance",
    "AddonAzureBackupAlerts"
  ]

  metric_categories = ["AllMetrics"]
}
