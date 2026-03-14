# firewall/paloalto — PAN-OS Configuration (Terraform)

Manages Palo Alto firewall and Panorama policy configuration via the `panos` Terraform provider. This is separate from the VM provisioning in `firewall/` — it configures the **running policy** on the appliances themselves.

**Target devices:** `ACME-HEALTH-SVCS-FW` (firewall) and `ACME-HEALTH-SVCS-PANORAMA` (Panorama)
**Backend:** `acme-health-ddestorage` / container `terraform-state` / `firewall-panos.terraform.tfstate`

> **Note:** This module uses `client_id` / `client_secret` auth (service principal), not OIDC. It is not wired into the standard GitHub Actions CI/CD pipeline. Apply manually or via a dedicated pipeline.

---

## What's Configured

| File | Contents |
|---|---|
| `net_panos.tf` | Device and Panorama base configuration |
| `net_panos_objects.tf` | Address objects, address groups, service objects |
| `net_panos_policies.tf` | Security policy rulebase |
| `net_panos_ipsec.tf` | IPsec VPN tunnels and IKE gateways |
| `net_panos_testing.tf` | Test/lab policy rules (review before applying to prod) |

---

## How to Apply

Authentication uses a service principal — set credentials in `terraform.tfvars` or as environment variables:

```bash
cd firewall/paloalto/
terraform init
terraform plan
terraform apply
```

Required variables (in `terraform.tfvars`):
- `client_id`, `client_secret` — service principal credentials
- `tenant_id`, `main_subscription_id`, `firewall_subscription_id`, `logging_subscription_id`
- PAN-OS device hostnames/IPs and credentials (see `variables.tf`)

---

## Notes

- Changes here affect **live firewall policy** — always run `terraform plan` and review before `apply`
- `net_panos_testing.tf` contains test rules — ensure they are disabled or removed before applying to production
- This state is stored in `acme-health-ddestorage` (not `acme-health-terraform-state`) — different from all other modules
