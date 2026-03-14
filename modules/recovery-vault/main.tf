resource "azurerm_recovery_services_vault" "this" {
  name                = var.vault_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku

  soft_delete_enabled          = var.soft_delete_enabled
  immutability                 = var.immutability
  storage_mode_type            = "GeoRedundant"
  cross_region_restore_enabled = var.cross_region_restore_enabled

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# VM backup policies
resource "azurerm_backup_policy_vm" "vm_policies" {
  for_each = { for policy in var.vm_backup_policies : policy.name => policy }

  name                = each.value.name
  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.this.name

  timezone                       = lookup(each.value, "timezone", "UTC")
  policy_type                    = lookup(each.value, "policy_type", null)
  instant_restore_retention_days = lookup(each.value, "instant_restore_retention_days", null)

  backup {
    frequency = each.value.backup_frequency
    time      = each.value.backup_time
  }

  retention_daily {
    count = each.value.retention_daily_count
  }

  dynamic "retention_weekly" {
    for_each = lookup(each.value, "retention_weekly_count", null) != null ? [1] : []
    content {
      count    = each.value.retention_weekly_count
      weekdays = lookup(each.value, "retention_weekly_weekdays", ["Sunday"])
    }
  }

  dynamic "retention_monthly" {
    for_each = lookup(each.value, "retention_monthly_count", null) != null ? [1] : []
    content {
      count    = each.value.retention_monthly_count
      weekdays = lookup(each.value, "retention_monthly_weekdays", ["Sunday"])
      weeks    = lookup(each.value, "retention_monthly_weeks", ["First"])
    }
  }

  dynamic "retention_yearly" {
    for_each = lookup(each.value, "retention_yearly_count", null) != null ? [1] : []
    content {
      count    = each.value.retention_yearly_count
      months   = lookup(each.value, "retention_yearly_months", ["January"])
      weekdays = lookup(each.value, "retention_yearly_weekdays", ["Sunday"])
      weeks    = lookup(each.value, "retention_yearly_weeks", ["First"])
    }
  }
}

# SQL backup policies
resource "azurerm_backup_policy_vm_workload" "sql_policies" {
  for_each = { for policy in var.sql_backup_policies : policy.name => policy }

  name                = each.value.name
  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.this.name
  workload_type       = "SQLDataBase"

  settings {
    time_zone           = lookup(each.value, "timezone", "UTC")
    compression_enabled = lookup(each.value, "compression_enabled", true)
  }

  protection_policy {
    policy_type = "Full"

    backup {
      frequency = lookup(each.value, "full_backup_frequency", "Daily")
      time      = lookup(each.value, "full_backup_time", "23:00")
    }

    retention_daily {
      count = lookup(each.value, "retention_daily_count", 30)
    }

    dynamic "retention_weekly" {
      for_each = lookup(each.value, "retention_weekly_count", null) != null ? [1] : []
      content {
        count    = each.value.retention_weekly_count
        weekdays = lookup(each.value, "retention_weekly_weekdays", ["Sunday"])
      }
    }

    dynamic "retention_monthly" {
      for_each = lookup(each.value, "retention_monthly_count", null) != null ? [1] : []
      content {
        count       = each.value.retention_monthly_count
        format_type = "Weekly"
        weekdays    = lookup(each.value, "retention_monthly_weekdays", ["Sunday"])
        weeks       = lookup(each.value, "retention_monthly_weeks", ["First"])
      }
    }

    dynamic "retention_yearly" {
      for_each = lookup(each.value, "retention_yearly_count", null) != null ? [1] : []
      content {
        count       = each.value.retention_yearly_count
        format_type = "Weekly"
        months      = lookup(each.value, "retention_yearly_months", ["January"])
        weekdays    = lookup(each.value, "retention_yearly_weekdays", ["Sunday"])
        weeks       = lookup(each.value, "retention_yearly_weeks", ["First"])
      }
    }
  }

  dynamic "protection_policy" {
    for_each = lookup(each.value, "log_backup_enabled", true) ? [1] : []
    content {
      policy_type = "Log"

      backup {
        frequency_in_minutes = lookup(each.value, "log_backup_frequency_minutes", 60)
      }

      simple_retention {
        count = lookup(each.value, "log_retention_days", 7)
      }
    }
  }
}

# File share backup policies
resource "azurerm_backup_policy_file_share" "file_share_policies" {
  for_each = { for policy in var.file_share_backup_policies : policy.name => policy }

  name                = each.value.name
  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.this.name

  timezone = lookup(each.value, "timezone", "UTC")

  backup {
    frequency = lookup(each.value, "backup_frequency", "Daily")
    time      = lookup(each.value, "backup_time", "23:00")
  }

  retention_daily {
    count = lookup(each.value, "retention_daily_count", 30)
  }

  dynamic "retention_weekly" {
    for_each = lookup(each.value, "retention_weekly_count", null) != null ? [1] : []
    content {
      count    = each.value.retention_weekly_count
      weekdays = lookup(each.value, "retention_weekly_weekdays", ["Sunday"])
    }
  }

  dynamic "retention_monthly" {
    for_each = lookup(each.value, "retention_monthly_count", null) != null ? [1] : []
    content {
      count    = each.value.retention_monthly_count
      weekdays = lookup(each.value, "retention_monthly_weekdays", ["Sunday"])
      weeks    = lookup(each.value, "retention_monthly_weeks", ["First"])
    }
  }

  dynamic "retention_yearly" {
    for_each = lookup(each.value, "retention_yearly_count", null) != null ? [1] : []
    content {
      count    = each.value.retention_yearly_count
      months   = lookup(each.value, "retention_yearly_months", ["January"])
      weekdays = lookup(each.value, "retention_yearly_weekdays", ["Sunday"])
      weeks    = lookup(each.value, "retention_yearly_weeks", ["First"])
    }
  }
}
