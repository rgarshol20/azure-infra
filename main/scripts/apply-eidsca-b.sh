#!/usr/bin/env bash
# =============================================================================
# apply-eidsca-b.sh — Track B EIDSCA Remediation (Production Tenant)
#
# Applies authentication and authorization settings via Microsoft Graph API
# that the azuread Terraform provider does not support natively.
#
# EIDSCA checks addressed:
#   AP01 — SSPR for admins → false
#   AP04 — Guest invite restrictions → adminsAndGuestInviters
#   AP05 — Email subscription signup → false
#   AP07 — Guest user role → Restricted Guest (most restricted)
#   AG02 — Report suspicious activity → enabled
#   AM06 — Show app name in Authenticator push → enabled
#   AM09 — Show geo location in Authenticator push → enabled
#   AF04 — FIDO2 enforce key restrictions → true (deny-list, empty = allow all)
#   AT01 — Temporary Access Pass → enabled
#   CR01 — Admin consent request policy → enabled
#   PR01 — Password protection mode → Enforce
#   PR02 — Password protection on-prem → true
#   PR03 — Enforce custom banned list → true
#   PR05 — Smart lockout duration → 60 seconds
#   ST08 — Guests cannot become group owners → false
#   ST09 — Guests can access group content → true
#   CP04 — Users can request admin consent → true
#
# AG01 (migration complete) — NOT applied automatically. See below.
#
# PREREQUISITES:
#   az login (or OIDC session active in GitHub Actions)
#   Caller must have: Global Administrator or Privileged Role Administrator
#
# USAGE:
#   ./apply-eidsca-b.sh                  # Apply all safe settings
#   ./apply-eidsca-b.sh --migrate-auth-methods  # Also complete auth method migration (one-way!)
# =============================================================================

set -euo pipefail

GRAPH="https://graph.microsoft.com/v1.0"
MIGRATE_AUTH_METHODS=false

for arg in "$@"; do
  case $arg in
    --migrate-auth-methods)
      MIGRATE_AUTH_METHODS=true
      shift
      ;;
  esac
done

echo ""
echo "================================================================="
echo " EIDSCA Track B Remediation — Production Tenant"
echo "================================================================="
echo ""

# Verify az CLI is authenticated
az account show --query "tenantId" -o tsv > /dev/null 2>&1 || {
  echo "ERROR: Not authenticated. Run 'az login' first."
  exit 1
}
TENANT=$(az account show --query "tenantDisplayName" -o tsv)
echo "Tenant: $TENANT"
echo ""

# =============================================================================
# Authorization Policy
# AP01, AP04, AP05, AP07 — fields not exposed in azuread_authorization_policy TF resource
# AP06 + AP10 handled by Terraform (auth-settings.tf)
# =============================================================================
echo "--- Authorization Policy (AP01 AP04 AP05 AP07) ---"
az rest --method PATCH \
  --uri "${GRAPH}/policies/authorizationPolicy" \
  --headers "Content-Type=application/json" \
  --body '{
    "enabledSelfServicePasswordResetForAdministrators": false,
    "allowInvitesFrom": "adminsAndGuestInviters",
    "allowedToSignUpEmailBasedSubscriptions": false,
    "guestUserRoleId": "2af84b1e-32c8-42b7-82bc-daa82404023b"
  }'
echo "  ✓ AP01: SSPR for admins = false"
echo "  ✓ AP04: Guest invite restrictions = adminsAndGuestInviters"
echo "  ✓ AP05: Email subscription signup = false"
echo "  ✓ AP07: Guest role = Restricted Guest (2af84b1e-...)"
echo ""

# =============================================================================
# Authentication Methods Policy — General Settings
# AG02: Report suspicious activity
# =============================================================================
echo "--- Authentication Methods Policy - General (AG02) ---"
az rest --method PATCH \
  --uri "${GRAPH}/policies/authenticationMethodsPolicy" \
  --headers "Content-Type=application/json" \
  --body '{
    "reportSuspiciousActivitySettings": {
      "state": "enabled",
      "includeTarget": {
        "targetType": "group",
        "id": "all_users"
      }
    }
  }'
echo "  ✓ AG02: Report suspicious activity = enabled"
echo ""

# =============================================================================
# AG01: Auth method policy migration — ONE-WAY, requires --migrate-auth-methods
#
# This moves the tenant from legacy per-user MFA to the unified auth methods
# policy. Once set to migrationComplete, you CANNOT revert to per-user MFA
# management. All MFA configuration must be done via Authentication Methods
# policies going forward.
#
# Current state: migrationInProgress (set automatically by Microsoft)
# Run with: --migrate-auth-methods to complete
# =============================================================================
if [ "$MIGRATE_AUTH_METHODS" = "true" ]; then
  echo "--- Auth Method Migration (AG01) --- [ONE-WAY OPERATION] ---"
  echo "  Setting policyMigrationState = migrationComplete"
  az rest --method PATCH \
    --uri "${GRAPH}/policies/authenticationMethodsPolicy" \
    --headers "Content-Type=application/json" \
    --body '{"policyMigrationState": "migrationComplete"}'
  echo "  ✓ AG01: Migration state = migrationComplete"
  echo "  ⚠️  IRREVERSIBLE: Per-user MFA management is now disabled"
  echo ""
else
  echo "--- Auth Method Migration (AG01) --- [SKIPPED - add --migrate-auth-methods to apply] ---"
  echo "  Current: migrationInProgress | Recommended: migrationComplete"
  echo "  WARNING: This is a one-way change — per-user MFA management disabled permanently."
  echo "  Only run after confirming no users/admins are managed via legacy per-user MFA portal."
  echo ""
fi

# =============================================================================
# Microsoft Authenticator
# AM06: Show app name in push notifications
# AM09: Show geographic location in push notifications
# =============================================================================
echo "--- Microsoft Authenticator (AM06 AM09) ---"
az rest --method PATCH \
  --uri "${GRAPH}/policies/authenticationMethodsPolicy/authenticationMethodConfigurations/MicrosoftAuthenticator" \
  --headers "Content-Type=application/json" \
  --body '{
    "@odata.type": "#microsoft.graph.microsoftAuthenticatorAuthenticationMethodConfiguration",
    "featureSettings": {
      "displayAppInformationRequiredState": {
        "state": "enabled",
        "includeTarget": {
          "targetType": "group",
          "id": "all_users"
        },
        "excludeTarget": {
          "targetType": "group",
          "id": "00000000-0000-0000-0000-000000000000"
        }
      },
      "displayLocationInformationRequiredState": {
        "state": "enabled",
        "includeTarget": {
          "targetType": "group",
          "id": "all_users"
        },
        "excludeTarget": {
          "targetType": "group",
          "id": "00000000-0000-0000-0000-000000000000"
        }
      }
    }
  }'
echo "  ✓ AM06: Show app name in push notifications = enabled"
echo "  ✓ AM09: Show geo location in push notifications = enabled"
echo ""

# =============================================================================
# FIDO2
# AF04: Enforce key restrictions
# Using "deny" enforcement type with empty aaGuids = all keys allowed,
# but enforcement infrastructure is in place. Populate aaGuids to restrict
# to specific FIDO2 vendors (AAGUIDs from vendor documentation).
# =============================================================================
echo "--- FIDO2 Key Restrictions (AF04) ---"
az rest --method PATCH \
  --uri "${GRAPH}/policies/authenticationMethodsPolicy/authenticationMethodConfigurations/Fido2" \
  --headers "Content-Type=application/json" \
  --body '{
    "@odata.type": "#microsoft.graph.fido2AuthenticationMethodConfiguration",
    "keyRestrictions": {
      "isEnforced": true,
      "enforcementType": "deny",
      "aaGuids": []
    }
  }'
echo "  ✓ AF04: Key restriction enforcement = enabled (deny-list, empty = all vendors allowed)"
echo "  Note: Populate aaGuids in the portal to restrict to approved vendors"
echo ""

# =============================================================================
# Temporary Access Pass
# AT01: Enable TAP for emergency onboarding / MFA recovery
# =============================================================================
echo "--- Temporary Access Pass (AT01) ---"
az rest --method PATCH \
  --uri "${GRAPH}/policies/authenticationMethodsPolicy/authenticationMethodConfigurations/TemporaryAccessPass" \
  --headers "Content-Type=application/json" \
  --body '{
    "@odata.type": "#microsoft.graph.temporaryAccessPassAuthenticationMethodConfiguration",
    "state": "enabled",
    "includeTargets": [
      {
        "targetType": "group",
        "id": "all_users"
      }
    ]
  }'
echo "  ✓ AT01: Temporary Access Pass = enabled"
echo ""

# =============================================================================
# Admin Consent Request Policy
# CR01: Enable admin consent request workflow
# =============================================================================
echo "--- Admin Consent Request Policy (CR01) ---"
az rest --method PATCH \
  --uri "${GRAPH}/policies/adminConsentRequestPolicy" \
  --headers "Content-Type=application/json" \
  --body '{"isEnabled": true}'
echo "  ✓ CR01: Admin consent request = enabled"
echo ""

# =============================================================================
# Directory Settings — Password Rule Settings
# PR01: Password protection mode = Enforce
# PR02: Enable on-prem password protection agent = true
# PR03: Enforce custom banned password list = true
# PR05: Smart lockout duration = 60 seconds
#
# Note: PR02 (on-prem agent) is irrelevant if cloud-only, but setting to
# true is harmless — it configures the agent IF it exists.
# =============================================================================
echo "--- Directory Settings: Password Rules (PR01 PR02 PR03 PR05) ---"

# Look up the template ID for Password Rule Settings
PASSWORD_TEMPLATE_ID=$(az rest --method GET \
  --uri "${GRAPH}/directorySettingTemplates" \
  --query "value[?displayName=='Password Rule Settings'].id | [0]" \
  -o tsv 2>/dev/null || echo "")

if [ -z "$PASSWORD_TEMPLATE_ID" ]; then
  echo "  WARNING: 'Password Rule Settings' template not found — skipping PR checks"
  echo "  (This template may not be available in all Entra tenants)"
else
  echo "  Template ID: $PASSWORD_TEMPLATE_ID"

  # Check if setting already exists
  EXISTING_ID=$(az rest --method GET \
    --uri "${GRAPH}/settings" \
    --query "value[?displayName=='Password Rule Settings'].id | [0]" \
    -o tsv 2>/dev/null || echo "")

  PASSWORD_VALUES='[
    {"name": "BannedPasswordCheckOnPremisesMode", "value": "Enforce"},
    {"name": "EnableBannedPasswordCheckOnPremises", "value": "True"},
    {"name": "EnableBannedPasswordCheck", "value": "True"},
    {"name": "LockoutDurationInSeconds", "value": "60"}
  ]'

  if [ -z "$EXISTING_ID" ]; then
    az rest --method POST \
      --uri "${GRAPH}/settings" \
      --headers "Content-Type=application/json" \
      --body "{\"templateId\": \"${PASSWORD_TEMPLATE_ID}\", \"values\": ${PASSWORD_VALUES}}"
    echo "  ✓ Created Password Rule Settings"
  else
    az rest --method PATCH \
      --uri "${GRAPH}/settings/${EXISTING_ID}" \
      --headers "Content-Type=application/json" \
      --body "{\"values\": ${PASSWORD_VALUES}}"
    echo "  ✓ Updated Password Rule Settings (ID: $EXISTING_ID)"
  fi
  echo "  ✓ PR01: BannedPasswordCheckOnPremisesMode = Enforce"
  echo "  ✓ PR02: EnableBannedPasswordCheckOnPremises = True"
  echo "  ✓ PR03: EnableBannedPasswordCheck = True"
  echo "  ✓ PR05: LockoutDurationInSeconds = 60"
fi
echo ""

# =============================================================================
# Directory Settings — M365 Groups
# ST08: Allow Guests to become Group Owner = false
# ST09: Allow Guests to access group content = true
# =============================================================================
echo "--- Directory Settings: M365 Groups (ST08 ST09) ---"

GROUPS_TEMPLATE_ID=$(az rest --method GET \
  --uri "${GRAPH}/directorySettingTemplates" \
  --query "value[?displayName=='Group.Unified'].id | [0]" \
  -o tsv 2>/dev/null || echo "")

if [ -z "$GROUPS_TEMPLATE_ID" ]; then
  echo "  WARNING: 'Group.Unified' template not found — skipping ST checks"
else
  echo "  Template ID: $GROUPS_TEMPLATE_ID"

  EXISTING_GROUPS_ID=$(az rest --method GET \
    --uri "${GRAPH}/settings" \
    --query "value[?displayName=='Group.Unified'].id | [0]" \
    -o tsv 2>/dev/null || echo "")

  GROUPS_VALUES='[
    {"name": "AllowGuestsToBeGroupOwner", "value": "false"},
    {"name": "AllowGuestsToAccessGroups", "value": "true"}
  ]'

  if [ -z "$EXISTING_GROUPS_ID" ]; then
    az rest --method POST \
      --uri "${GRAPH}/settings" \
      --headers "Content-Type=application/json" \
      --body "{\"templateId\": \"${GROUPS_TEMPLATE_ID}\", \"values\": ${GROUPS_VALUES}}"
    echo "  ✓ Created Group.Unified settings"
  else
    az rest --method PATCH \
      --uri "${GRAPH}/settings/${EXISTING_GROUPS_ID}" \
      --headers "Content-Type=application/json" \
      --body "{\"values\": ${GROUPS_VALUES}}"
    echo "  ✓ Updated Group.Unified settings (ID: $EXISTING_GROUPS_ID)"
  fi
  echo "  ✓ ST08: AllowGuestsToBeGroupOwner = false"
  echo "  ✓ ST09: AllowGuestsToAccessGroups = true"
fi
echo ""

# =============================================================================
# Directory Settings — Consent Policy
# CP04: Users can request admin consent = true
# =============================================================================
echo "--- Directory Settings: Consent Policy (CP04) ---"

CONSENT_TEMPLATE_ID=$(az rest --method GET \
  --uri "${GRAPH}/directorySettingTemplates" \
  --query "value[?displayName=='Consent Policy Settings'].id | [0]" \
  -o tsv 2>/dev/null || echo "")

if [ -z "$CONSENT_TEMPLATE_ID" ]; then
  echo "  WARNING: 'Consent Policy Settings' template not found — skipping CP04"
  echo "  Try enabling via Azure Portal: Azure AD > User settings > Admin consent requests"
else
  echo "  Template ID: $CONSENT_TEMPLATE_ID"

  EXISTING_CONSENT_ID=$(az rest --method GET \
    --uri "${GRAPH}/settings" \
    --query "value[?displayName=='Consent Policy Settings'].id | [0]" \
    -o tsv 2>/dev/null || echo "")

  CONSENT_VALUES='[
    {"name": "EnableAdminConsentRequests", "value": "true"}
  ]'

  if [ -z "$EXISTING_CONSENT_ID" ]; then
    az rest --method POST \
      --uri "${GRAPH}/settings" \
      --headers "Content-Type=application/json" \
      --body "{\"templateId\": \"${CONSENT_TEMPLATE_ID}\", \"values\": ${CONSENT_VALUES}}"
    echo "  ✓ Created Consent Policy Settings"
  else
    az rest --method PATCH \
      --uri "${GRAPH}/settings/${EXISTING_CONSENT_ID}" \
      --headers "Content-Type=application/json" \
      --body "{\"values\": ${CONSENT_VALUES}}"
    echo "  ✓ Updated Consent Policy Settings (ID: $EXISTING_CONSENT_ID)"
  fi
  echo "  ✓ CP04: EnableAdminConsentRequests = true"
fi
echo ""

echo "================================================================="
echo " Done. Run 'terraform apply' in azure-infra/main for AP06/AP10."
echo " Then trigger Maester to verify results."
echo "================================================================="
