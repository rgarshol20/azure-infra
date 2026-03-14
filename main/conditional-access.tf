# =============================================================================
# Conditional Access Policies
#
# ALL policies MUST exclude the break glass group.
# Reference: azuread_group.break_glass_exclusion (defined in break-glass.tf)
#
# BEFORE APPLYING: Confirm no printers, scanners, or legacy apps use
# SMTP/IMAP/POP basic auth — those will break when this policy enables.
# Check: Azure AD > Sign-in logs > filter Client App = "Exchange ActiveSync",
#        "IMAP", "MAPI", "POP3", "SMTP", "Other clients" for recent activity.
# =============================================================================

# =============================================================================
# Block Legacy Authentication (MT.1009, MT.1010, CISA.MS.AAD.1.1)
#
# Targets: Exchange ActiveSync clients + all other legacy auth protocols
#          (IMAP, POP3, SMTP basic auth, older Office clients, etc.)
# Excludes: Break glass group (always — see break-glass.tf)
# =============================================================================
resource "azuread_conditional_access_policy" "block_legacy_auth" {
  display_name = "CA-Block-LegacyAuthentication"
  state        = "enabled"

  conditions {
    # Only legacy auth protocols — does NOT affect browser or modern auth clients
    client_app_types = ["exchangeActiveSync", "other"]

    applications {
      included_applications = ["All"]
    }

    users {
      included_users  = ["All"]
      excluded_groups = [azuread_group.break_glass_exclusion.object_id]
      excluded_users = [
        "a42e11b8-8988-4595-99a7-1261735cfcac", # TODO: identify this account — verify legacy auth requirement
        "6a9b81e7-cd1c-492f-a4ce-fde3081bd4b0", # TODO: identify this account — verify legacy auth requirement
        "09dbf970-ecaf-48cd-895c-c9e527358da5", # TODO: identify this account — verify legacy auth requirement
        "37269bd5-1eef-4a95-89d6-6e456851a399", # TODO: identify this account — verify legacy auth requirement
      ]
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["block"]
  }
}
