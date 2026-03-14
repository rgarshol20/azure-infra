# Remote state module for cross-environment references
# Replaces inline data "terraform_remote_state" blocks

module "remote_state" {
  source = "../modules/remote-state"

  # Defaults match current configuration:
  # - state_resource_group  = "rg-main-terraform"
  # - state_storage_account = "acme-health-terraform-state"
  # - state_container       = "terraform-state"
  # - use_azuread_auth      = true
  # - use_oidc              = true
}
