# Azure Multi-Tenant Cost Waste Audit Report
**Date:** 2026-03-04
**Scanned:** 9 subscriptions across 2 tenants

---

## TENANT 1: PRODUCTION (5 subscriptions)

### Subscription: Prod
─────────────────────────────────────────────
Unattached disks:           1 disk (~$5-15/mo est.)
Unattached public IPs:      0
Stopped VMs w/ Premium:     0
Orphan NICs:                0
Orphan NSGs:                0
Empty resource groups:      11
Old snapshots (>90d):       7 (est. 700 GB, ~$35/mo)
Unused storage accounts:    0
Advisor cost recs:          2 recommendations
Oversized VMs:              16 VMs running (review via Advisor)
LAW workspaces:             1 (acme-health-prod-law, 30-day retention)
Defender unused plans:      0
─────────────────────────────────────────────
**Estimated monthly waste:  ~$40-50**

### Subscription: Dashboard (AcmeHealthCustomers)
─────────────────────────────────────────────
Unattached disks:           1 disk (~$5-15/mo est.)
Unattached public IPs:      0
Stopped VMs w/ Premium:     1 VM (check disk costs)
Orphan NICs:                0
Orphan NSGs:                0
Empty resource groups:      12
Old snapshots (>90d):       18 (est. 1800 GB, ~$90/mo)
Unused storage accounts:    1 (review utilization)
Advisor cost recs:          6 recommendations
Oversized VMs:              8 VMs running (review via Advisor)
LAW workspaces:             1
Defender unused plans:      0
─────────────────────────────────────────────
**Estimated monthly waste:  ~$100-120**

### Subscription: Firewall (AcmeHealthSvcs)
─────────────────────────────────────────────
Unattached disks:           7 disks (~$35-100/mo est.)
Unattached public IPs:      0
Stopped VMs w/ Premium:     1 VM (check disk costs)
Orphan NICs:                0
Orphan NSGs:                2
Empty resource groups:      12
Old snapshots (>90d):       28 (est. 2800 GB, ~$140/mo)
Unused storage accounts:    1 (review utilization)
Advisor cost recs:          9 recommendations
Oversized VMs:              16 VMs running (review via Advisor)
LAW workspaces:             2
Defender unused plans:      0
─────────────────────────────────────────────
**Estimated monthly waste:  ~$175-240**

### Subscription: Dev
─────────────────────────────────────────────
Unattached disks:           0
Unattached public IPs:      0
Stopped VMs w/ Premium:     0
Orphan NICs:                0
Orphan NSGs:                0
Empty resource groups:      8
Old snapshots (>90d):       0
Unused storage accounts:    0
Advisor cost recs:          1 recommendation
Oversized VMs:              2 VMs running (minimal environment)
LAW workspaces:             1
Defender unused plans:      0
─────────────────────────────────────────────
**Estimated monthly waste:  ~$0-10**

### Subscription: Identity
─────────────────────────────────────────────
Unattached disks:           0
Unattached public IPs:      0
Stopped VMs w/ Premium:     0
Orphan NICs:                0
Orphan NSGs:                0
Empty resource groups:      6
Old snapshots (>90d):       0
Unused storage accounts:    0
Advisor cost recs:          0 recommendations
Oversized VMs:              2 VMs running (minimal environment)
LAW workspaces:             1
Defender unused plans:      0
─────────────────────────────────────────────
**Estimated monthly waste:  ~$0**

---
**TENANT 1 TOTAL WASTE:** ~$315-420/month

---

## TENANT 2: DDE (4 subscriptions)

### Subscription: DDE-Main
─────────────────────────────────────────────
Unattached disks:           0
Unattached public IPs:      0
Stopped VMs w/ Premium:     0
Orphan NICs:                0
Orphan NSGs:                0
Empty resource groups:      2
Old snapshots (>90d):       0
Unused storage accounts:    1 (review utilization)
Advisor cost recs:          0 recommendations
Oversized VMs:              0 VMs (infrastructure subscription)
LAW workspaces:             1
Defender unused plans:      0
─────────────────────────────────────────────
**Estimated monthly waste:  ~$0**

### Subscription: DDE-Logging
─────────────────────────────────────────────
Unattached disks:           0
Unattached public IPs:      0
Stopped VMs w/ Premium:     0
Orphan NICs:                0
Orphan NSGs:                0
Empty resource groups:      2
Old snapshots (>90d):       0
Unused storage accounts:    1 (review utilization)
Advisor cost recs:          0 recommendations
Oversized VMs:              0 VMs (logging subscription)
LAW workspaces:             1
Defender unused plans:      0
─────────────────────────────────────────────
**Estimated monthly waste:  ~$0**

### Subscription: DDE-Billings
─────────────────────────────────────────────
Unattached disks:           0
Unattached public IPs:      0
Stopped VMs w/ Premium:     0
Orphan NICs:                0
Orphan NSGs:                0
Empty resource groups:      6
Old snapshots (>90d):       0
Unused storage accounts:    0
Advisor cost recs:          10 recommendations
Oversized VMs:              7 VMs running (review via Advisor)
LAW workspaces:             1
Defender unused plans:      0
─────────────────────────────────────────────
**Estimated monthly waste:  ~$0-30 (pending Advisor details)**

### Subscription: DDE-Firewall
─────────────────────────────────────────────
Unattached disks:           0
Unattached public IPs:      0
Stopped VMs w/ Premium:     0
Orphan NICs:                1
Orphan NSGs:                0
Empty resource groups:      5
Old snapshots (>90d):       0
Unused storage accounts:    0
Advisor cost recs:          19 recommendations (HIGHEST)
Oversized VMs:              7 VMs running (review via Advisor)
LAW workspaces:             1
Defender unused plans:      0
─────────────────────────────────────────────
**Estimated monthly waste:  ~$0-50 (pending Advisor details)**

---
**TENANT 2 TOTAL WASTE:** ~$0-80/month (significantly cleaner than Prod)

---

## GRAND TOTAL ACROSS BOTH TENANTS

**Combined Estimated Monthly Waste:** ~$315-500/month

---

## KEY FINDINGS

### High-Impact Items (Prod Tenant)
1. **Old Snapshots:** 53 snapshots >90 days old across Prod, Dashboard, and Firewall (~$265/mo)
   - Firewall: 28 snapshots (most costly)
   - Dashboard: 18 snapshots
   - Prod: 7 snapshots

2. **Unattached Disks:** 9 total disks not attached to any VM (~$40-130/mo)
   - Firewall: 7 disks (highest exposure)
   - Dashboard: 1 disk
   - Prod: 1 disk

3. **Empty Resource Groups:** 55 total across Prod tenant (cleanup candidates)

4. **Advisor Recommendations:** 18 cost recommendations in Prod tenant
   - Firewall: 9 recommendations (highest)
   - Dashboard: 6 recommendations

### DDE Tenant Status
- **Much cleaner** than expected
- Only 19 Advisor recommendations in DDE-Firewall warrant investigation
- 10 recommendations in DDE-Billings
- No significant unattached resources
- Minimal empty RGs

### Comparison to AWS Audit
- AWS: $233/month waste found
- Azure: $315-500/month estimated waste
- Azure waste is **35-115% higher** than AWS
- Primary drivers: snapshots and orphaned disks

---

## NEXT STEPS (AWAITING YOUR REVIEW)

### Immediate Actions (High ROI)
1. **Delete old snapshots** (>90 days) in Prod, Dashboard, Firewall (~$265/mo savings)
2. **Delete unattached disks** after verification they're not needed (~$40-130/mo savings)
3. **Review Advisor recommendations** in Firewall and Dashboard subscriptions

### Secondary Cleanup
4. Delete empty resource groups (55 total in Prod tenant)
5. Remove orphan NSGs (2 in Firewall)
6. Investigate stopped VMs in Dashboard and Firewall (1 each) - delete or start?

### Requires Further Investigation
7. Storage accounts with minimal usage (3 total)
8. Advisor right-sizing recommendations (requires workload analysis)
9. DDE-Firewall's 19 Advisor recommendations (unknown savings potential)

---

**REPORT COMPLETE - NO RESOURCES MODIFIED**

All raw audit data saved in: `/tmp/audit-*.txt`
Parsed data available in: `/tmp/analysis-results.json`

Ready for your review and approval to proceed with deletions.
