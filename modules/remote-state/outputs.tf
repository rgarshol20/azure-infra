output "logging" {
  description = "Logging module remote state"
  value       = data.terraform_remote_state.logging
}

output "main" {
  description = "Main module remote state"
  value       = data.terraform_remote_state.main
}

output "identity" {
  description = "Identity module remote state"
  value       = data.terraform_remote_state.identity
}

output "firewall" {
  description = "Firewall module remote state"
  value       = data.terraform_remote_state.firewall
}

output "prod" {
  description = "Production module remote state"
  value       = data.terraform_remote_state.prod
}

output "dev" {
  description = "Development module remote state"
  value       = data.terraform_remote_state.dev
}

output "dashboard" {
  description = "Dashboard module remote state"
  value       = data.terraform_remote_state.dashboard
}
