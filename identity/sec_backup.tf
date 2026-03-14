module "recovery_vault" {
  source = "../modules/recovery-vault"
  providers = {
    azurerm = azurerm.identity
  }

  vault_name          = "rsv-core-identity"
  location            = azurerm_resource_group.backup.location
  resource_group_name = azurerm_resource_group.backup.name

  soft_delete_enabled = true
  immutability        = "Unlocked"

  vm_backup_policies = [
    {
      name                           = "AcmeHealthID"
      policy_type                    = "V2"
      backup_frequency               = "Daily"
      backup_time                    = "02:00"
      timezone                       = "UTC"
      instant_restore_retention_days = 7
      retention_daily_count          = 30
      retention_weekly_count         = 12
      retention_weekly_weekdays      = ["Sunday"]
    }
  ]

  tags = local.required_tags
}

moved {
  from = azurerm_recovery_services_vault.rsv
  to   = module.recovery_vault.azurerm_recovery_services_vault.this
}

moved {
  from = azurerm_backup_policy_vm.acme_health_id
  to   = module.recovery_vault.azurerm_backup_policy_vm.vm_policies["AcmeHealthID"]
}

# Diagnostic settings for Recovery Services Vault (HIPAA audit trail)
module "diag_rsv_identity" {
  source = "../modules/diagnostic-settings"

  diagnostic_setting_name    = "diag-rsv-identity"
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
