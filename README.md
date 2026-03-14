# azure-infra

Terraform infrastructure for AcmeHealth Group Azure environments. Seven subscriptions managed independently, each with its own state file, provider config, and GitHub Actions workflow.

---

## Repository Structure

| Directory | Subscription | Workflow |
|---|---|---|
| `main/` | Main (`ce62d93b`) | `deploy-main.yml` |
| `logging/` | Logging (`3946532a`) | `deploy-logging.yml` |
| `identity/` | Identity (`ac212528`) | `deploy-identity.yml` |
| `firewall/` | Firewall (`28bada8b`) | `deploy-firewall.yml` |
| `dev/` | Dev (`11781e6f`) | `deploy-dev.yml` |
| `prod/` | Prod (`db824d94`) | `deploy-prod.yml` |
| `dashboard/` | Dashboard (`77af0f6a`) | `deploy-dashboard.yml` |
| `modules/` | Shared Terraform modules | — |
| `function_app/` | Azure Function source (PA backup/audit) | — |

---

## Triggering Deployments

All workflows trigger automatically on push to `main` when files in their directory change, and support `workflow_dispatch` for manual runs.

### Trigger a specific workflow manually

```bash
gh workflow run deploy-main.yml
gh workflow run deploy-logging.yml
gh workflow run deploy-identity.yml
gh workflow run deploy-firewall.yml
gh workflow run deploy-dev.yml
gh workflow run deploy-prod.yml
gh workflow run deploy-dashboard.yml
```

### Trigger all at once

```bash
for wf in deploy-main deploy-logging deploy-identity deploy-firewall deploy-dev deploy-prod deploy-dashboard; do
  gh workflow run ${wf}.yml
  sleep 2
done
```

### Monitor runs

```bash
# List recent runs across all workflows
gh run list --limit 20

# Watch a specific run live
gh run watch $(gh run list --limit 1 --json databaseId -q '.[0].databaseId')

# View logs for a failed run
gh run view <run-id> --log-failed
```

---

## Authentication

All workflows use **Azure OIDC federation** — no stored credentials.

- OIDC only works from `refs/heads/main`. Feature branch runs are rejected with `AADSTS700213`.
- Each workflow logs in twice: first to the **Main subscription** (for backend state), then to the **target subscription** (for resource operations).
- The OIDC service principal is `ops-automation`.

---

## State Backend

All modules share one storage account:

| Setting | Value |
|---|---|
| Storage account | `acme-health-terraform-state` |
| Container | `terraform-state` |
| Subscription | Main (`ce62d93b-2e73-46e0-a3d6-6a99156e9741`) |

State files: `main.terraform.tfstate`, `logging.terraform.tfstate`, `identity.terraform.tfstate`, `firewall.terraform.tfstate`, `dev.terraform.tfstate`, `prod.terraform.tfstate`, `dashboard.terraform.tfstate`.

**If a state lock is stuck** (cancelled CI run or timeout):
```bash
az storage blob lease break \
  --blob-name <module>.terraform.tfstate \
  --container-name terraform-state \
  --account-name acme-health-terraform-state \
  --auth-mode login \
  --subscription ce62d93b-2e73-46e0-a3d6-6a99156e9741
```

---

## Local Development

Requires Terraform 1.9.8 (matches CI version) and Azure CLI.

```bash
az login
az account set --subscription <SUBSCRIPTION_ID>

cd <module>/
terraform init
terraform plan
terraform apply
```

> Local applies require your user account to have the same permissions as the `ops-automation` service principal. For prod environments, prefer triggering via CI/CD.

---

## Security Scanning

```bash
# Build scanner image once
cd checkov/ && docker build -t checkov:local .

# Scan a module
docker run --rm -v "$(pwd):/scan" checkov:local --directory /scan/<module> --framework terraform
```

Checkov also runs automatically on every PR via `security-checkov.yml`.

---

## Module READMEs

- [main/README.md](main/README.md) — Entra ID, governance, Defender, state storage
- [logging/README.md](logging/README.md) — Central LAW, EventHub, HIPAA archive
- [identity/README.md](identity/README.md) — AD domain controllers
- [firewall/README.md](firewall/README.md) — Palo Alto, Panorama, syslog, Arctic Wolf, Twingate
- [dev/README.md](dev/README.md) — Dev MySQL/SQL server
- [prod/README.md](prod/README.md) — Production Windows Server fleet
- [dashboard/README.md](dashboard/README.md) — DDE / Dashboard (mid-decommission)
- [modules/palo-alto-backup-azure/README.md](modules/palo-alto-backup-azure/README.md) — PA config backup Function App
