# Required tags per /git/infrastructure-docs/compliance/tagging-standard.md
# Migrated to use reusable tags module
module "logging_tags" {
  source = "../modules/tags"

  environment         = "shared"
  owner               = "it-security"
  managed_by          = "terraform"
  data_classification = "confidential"
  cost_center         = "it"
  compliance_scope    = "hipaa-soc2-hitrust"
}

# Create local for backward compatibility with existing resource references
locals {
  required_tags = module.logging_tags.required_tags
}
