locals {
  required_tags = {
    environment         = var.environment
    owner               = var.owner
    managed-by          = var.managed_by
    data-classification = var.data_classification
    cost-center         = var.cost_center
    compliance-scope    = var.compliance_scope
  }
}
