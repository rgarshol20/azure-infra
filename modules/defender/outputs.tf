output "servers_pricing_id" {
  description = "Defender for Servers pricing resource ID"
  value       = var.enable_defender_for_servers ? azurerm_security_center_subscription_pricing.servers[0].id : null
}

output "cspm_pricing_id" {
  description = "Defender CSPM pricing resource ID"
  value       = var.enable_defender_cspm ? azurerm_security_center_subscription_pricing.cspm[0].id : null
}

output "mde_windows_policy_id" {
  description = "MDE Windows extension policy assignment ID"
  value       = var.enable_mde_policies ? azurerm_subscription_policy_assignment.mde_windows[0].id : null
}

output "mde_linux_policy_id" {
  description = "MDE Linux extension policy assignment ID"
  value       = var.enable_mde_policies ? azurerm_subscription_policy_assignment.mde_linux[0].id : null
}

output "hipaa_policy_id" {
  description = "HIPAA HITRUST policy assignment ID"
  value       = var.enable_hipaa_policy ? azurerm_subscription_policy_assignment.hipaa[0].id : null
}

output "security_admin_role_assignment_ids" {
  description = "Security Admin role assignment IDs"
  value       = [for ra in azurerm_role_assignment.security_admin : ra.id]
}
