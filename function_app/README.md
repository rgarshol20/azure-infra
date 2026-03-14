# function_app — Azure Function Source

Python source for the Palo Alto config backup and security audit Azure Functions. Deployed via the `modules/palo-alto-backup-azure` Terraform module using zip deploy.

---

## Structure

```
function_app/
├── host.json                          # Azure Functions v2 runtime config
├── requirements.txt                   # Python dependencies
└── palo_alto_backup/
    ├── __init__.py
    ├── backup_handler.py              # Daily backup — timer trigger 02:30 UTC
    └── audit_handler.py              # Weekly audit — timer trigger Mon 06:30 UTC
```

---

## Functions

### `palo_alto_backup` (backup_handler.py)

Timer: `30 2 * * *` (daily 02:30 UTC)

1. Reads device list from `DEVICES` app setting (JSON)
2. Fetches API key per device from Key Vault (`{secret_name}` → `{"ip": "...", "api_key": "..."}`)
3. Exports running config via PAN-OS XML API (`/api/?type=export&category=configuration`)
4. SHA-256 hash comparison against previous run (stored in blob `hashes/{name}.sha256`)
5. Archives config to `archive/{name}/{timestamp}.xml`
6. Commits latest config to GitHub at `firewall-configs/{name}/running-config.xml`
7. Sends SES SMTP alert if config changed or backup failed

### `palo_alto_audit` (audit_handler.py)

Timer: `30 6 * * 1` (weekly Monday 06:30 UTC)

Reads config XML from blob (`{name}/running-config.xml`), runs 15 HIPAA security checks, sends HTML report via SES SMTP.

| Check ID | Category | What it checks |
|---|---|---|
| SEC-001 | Security Rules | Deny-all default rule present |
| SEC-002 | Security Rules | Inbound `any/any` allow rules |
| SEC-003 | Security Rules | Rules without security profiles |
| SEC-004 | Security Rules | Rules allowing application `any` |
| SEC-005 | Security Rules | Disabled rules (cleanup) |
| SEC-006 | Security Rules | Logging disabled on rules |
| MGMT-001 | Management | Management interface on public zone |
| MGMT-002 | Management | Permitted IP restrictions on management |
| ADMIN-001 | Admin Accounts | Default admin account still active |
| ADMIN-002 | Admin Accounts | Admin accounts with no MFA |
| ZONE-001 | Zone Protection | Zone protection profiles missing |
| LOG-001 | Logging | Syslog server configured |
| LOG-002 | Logging | Log forwarding profiles assigned to rules |
| LOG-003 | Logging | Threat logging enabled |
| TLS-001 | TLS/SSL | Weak TLS versions or cipher suites |
| AUTH-001 | Authentication | Password complexity policy |
| SYS-001 | System | NTP servers configured |

---

## App Settings (set by Terraform module)

| Setting | Source | Description |
|---|---|---|
| `DEVICES` | `var.devices` (JSON) | List of `{name, secret_name, type}` |
| `BACKUP_CONTAINER` | `var.backup_container` | Blob container name (default: `firewall-configs`) |
| `KEYVAULT_URI` | Key Vault resource | URI for secret lookups |
| `GITHUB_SECRET_NAME` | `var.github_secret_name` | KV secret with `{token, repo, branch}` |
| `SES_SMTP_SECRET_NAME` | `var.ses_smtp_secret_name` | KV secret with `{username, password}` |
| `SES_SENDER` | `var.ses_sender` | Verified SES sender email |
| `SES_RECIPIENT` | `var.ses_recipient` | Alert/report recipient |
| `SES_SMTP_HOST` | `var.ses_smtp_host` | SES SMTP endpoint |
| `BACKUP_STORAGE_CONN_STR` | Storage account | Connection string for blob access |

---

## Deployment

Code is deployed automatically by the Terraform `null_resource` in the module — it zip-deploys on every `terraform apply` when source files change (tracked via `filesha256` triggers).

To deploy manually:

```bash
cd function_app/
zip -r palo_alto_backup.zip palo_alto_backup/ host.json requirements.txt

az functionapp deployment source config-zip \
  --resource-group <rg> \
  --name palo-alto-backup-func \
  --src palo_alto_backup.zip
```

See [modules/palo-alto-backup-azure/README.md](../modules/palo-alto-backup-azure/README.md) for the full post-deploy setup guide (secret population, manual trigger commands, log streaming).

---

## Local Testing

```bash
pip install azure-functions azure-identity azure-keyvault-secrets azure-storage-blob

# Run a quick import check (no Azure creds needed)
python3 -c "import palo_alto_backup.backup_handler; print('OK')"
python3 -c "import palo_alto_backup.audit_handler; print('OK')"
```

For end-to-end testing, trigger via Azure Portal or:
```bash
az functionapp function invoke \
  --resource-group <rg> \
  --name palo-alto-backup-func \
  --function-name palo_alto_backup
```
