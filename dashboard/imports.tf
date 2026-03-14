#######################################################################
# Import block: restore Networking RG into state after partial apply
# The apply on 2026-03-06 destroyed the Twingate container groups and
# created new rg-dashboard-* resource groups, but the Networking RG
# was never deleted (cancel hit mid-destroy). Import it back so
# Terraform stops trying to recreate it and instead recreates only
# the missing Twingate connectors.
#######################################################################

import {
  to       = azurerm_resource_group.dashboard
  id       = "/subscriptions/${var.dashboard_subscription_id}/resourceGroups/Networking"
  provider = azurerm.dashboard
}
