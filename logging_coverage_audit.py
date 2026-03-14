
import os
import re
import pandas as pd

# Base directory to scan
base_path = "."

# Loggable Azure resource types
loggable_resource_types = [
    "azurerm_key_vault",
    "azurerm_storage_account",
    "azurerm_windows_virtual_machine",
    "azurerm_network_security_group",
    "azurerm_firewall",
    "azurerm_application_gateway",
    "azurerm_firewall_policy",
    "azurerm_virtual_network_gateway",
    "azurerm_lb",
    "azurerm_container_registry",
    "azurerm_app_service",
    "azurerm_sql_server",
    "azurerm_kubernetes_cluster"
]

# Track declarations and diagnostic settings
resource_declarations = {rtype: [] for rtype in loggable_resource_types}
diagnostic_targets = []

# Walk through all .tf files
for root, dirs, files in os.walk(base_path):
    for file in files:
        if file.endswith(".tf"):
            file_path = os.path.join(root, file)
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

                # Match resources
                for rtype in loggable_resource_types:
                    pattern = rf'resource\s+"{rtype}"\s+"(\w+)"'
                    matches = re.findall(pattern, content)
                    for m in matches:
                        resource_declarations[rtype].append((root, m))

                # Match diagnostic targets
                diag_pattern = r'target_resource_id\s+=\s+([^\s\n]+)'
                diag_matches = re.findall(diag_pattern, content)
                diagnostic_targets.extend(diag_matches)

# Find missing diagnostics
missing_logs = []
for rtype, entries in resource_declarations.items():
    for path, name in entries:
        resource_id_var = f"{rtype}.{name}.id"
        if not any(resource_id_var in d for d in diagnostic_targets):
            missing_logs.append({
                "Resource": f"{rtype}.{name}",
                "Logging Status": "❌ Missing diagnostic_setting",
                "Defined In": path
            })

# Create and save report
df = pd.DataFrame(missing_logs)
df.to_csv("logging_coverage_report.csv", index=False)
print("Report saved to logging_coverage_report.csv")
