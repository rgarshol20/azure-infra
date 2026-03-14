# Required tags per /git/infrastructure-docs/compliance/tagging-standard.md
# Migrated to use reusable tags module
module "dashboard_tags" {
  source = "../modules/tags"

  environment         = "shared"
  owner               = "it-security"
  managed_by          = "terraform"
  data_classification = "internal"
  cost_center         = "it"
  compliance_scope    = "soc2-hitrust"
}

# Create local for backward compatibility with existing resource references
locals {
  required_tags = module.dashboard_tags.required_tags
}
