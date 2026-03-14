#!/bin/bash
# Generate HTML report from Checkov JSON output

SCAN_DIR="${1:-.}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPORT_DIR="$SCRIPT_DIR/reports"

mkdir -p "$REPORT_DIR"

echo "🔍 Running Checkov and generating HTML report..."

# First, generate JSON report
docker run --rm \
  -v "$(pwd):/scan" \
  -v "$REPORT_DIR:/reports" \
  checkov:local \
  -d "/scan/${SCAN_DIR}" \
  --framework terraform \
  --check CKV_AZURE_*,CKV_AWS_* \
  --output json \
  --output-file-path /reports/checkov_${TIMESTAMP}.json \
  --soft-fail

# Generate simple HTML from JSON
HTML_FILE="$REPORT_DIR/checkov_report_${TIMESTAMP}.html"

cat > "$HTML_FILE" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Checkov Security Scan Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 3px solid #e74c3c; padding-bottom: 10px; }
        .summary { display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; margin: 20px 0; }
        .stat-box { background: #ecf0f1; padding: 15px; border-radius: 5px; text-align: center; }
        .stat-box.failed { background: #e74c3c; color: white; }
        .stat-box.passed { background: #27ae60; color: white; }
        .stat-box h2 { margin: 0; font-size: 2em; }
        .stat-box p { margin: 5px 0 0 0; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #34495e; color: white; }
        tr:hover { background-color: #f5f5f5; }
        .severity-high { color: #e74c3c; font-weight: bold; }
        .severity-medium { color: #f39c12; font-weight: bold; }
        .severity-low { color: #3498db; }
        .file-path { font-family: monospace; font-size: 0.9em; color: #7f8c8d; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔒 Checkov Security Scan Report</h1>
        <p>Generated: TIMESTAMP_PLACEHOLDER</p>
        <div id="content">Loading report data...</div>
    </div>
    <script>
        fetch('checkov_TIMESTAMP_PLACEHOLDER.json')
            .then(response => response.json())
            .then(data => {
                const summary = data.summary || {};
                const failed = data.results?.failed_checks || [];
                const passed = data.results?.passed_checks || [];
                
                let html = '<div class="summary">';
                html += \`<div class="stat-box failed"><h2>\${failed.length}</h2><p>Failed Checks</p></div>\`;
                html += \`<div class="stat-box passed"><h2>\${passed.length}</h2><p>Passed Checks</p></div>\`;
                html += \`<div class="stat-box"><h2>\${summary.resource_count || 0}</h2><p>Resources Scanned</p></div>\`;
                html += \`<div class="stat-box"><h2>\${((passed.length / (failed.length + passed.length)) * 100).toFixed(1)}%</h2><p>Pass Rate</p></div>\`;
                html += '</div>';
                
                if (failed.length > 0) {
                    html += '<h2>❌ Failed Checks</h2>';
                    html += '<table><thead><tr><th>Check ID</th><th>Severity</th><th>Resource</th><th>File</th><th>Description</th></tr></thead><tbody>';
                    failed.forEach(check => {
                        const severity = check.check_class?.split('.')?.pop()?.toLowerCase() || 'medium';
                        html += \`<tr>
                            <td><code>\${check.check_id}</code></td>
                            <td class="severity-\${severity}">\${severity.toUpperCase()}</td>
                            <td><code>\${check.resource}</code></td>
                            <td class="file-path">\${check.file_path}:\${check.file_line_range?.[0] || ''}</td>
                            <td>\${check.check_name}</td>
                        </tr>\`;
                    });
                    html += '</tbody></table>';
                }
                
                document.getElementById('content').innerHTML = html;
            })
            .catch(err => {
                document.getElementById('content').innerHTML = '<p style="color: red;">Error loading report data: ' + err + '</p>';
            });
    </script>
</body>
</html>
EOF

# Replace timestamp placeholders
sed -i "s/TIMESTAMP_PLACEHOLDER/$TIMESTAMP/g" "$HTML_FILE"

echo ""
echo "✅ HTML Report generated: $HTML_FILE"
echo "   Open in browser: file://$HTML_FILE"