#!/bin/bash
# Generate CSV report for tracking fixes

SCAN_DIR="${1:-.}"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPORT_DIR="$SCRIPT_DIR/reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$REPORT_DIR"

echo "🔍 Generating CSV report for issue tracking..."

# Generate JSON first
docker run --rm \
  -v "$(pwd):/scan" \
  -v "$REPORT_DIR:/reports" \
  checkov:local \
  -d "/scan/${SCAN_DIR}" \
  --framework terraform \
  --check CKV_AZURE_*,CKV_AWS_* \
  --output json \
  --output-file-path /reports/temp_${TIMESTAMP}.json \
  --soft-fail

# Check if JSON file was created
JSON_FILE=$(ls "$REPORT_DIR"/temp_${TIMESTAMP}*.json 2>/dev/null | head -1)

if [ -z "$JSON_FILE" ]; then
    echo "❌ Error: JSON file not generated"
    exit 1
fi

echo "📄 Processing: $JSON_FILE"

# Convert JSON to CSV using Docker Python
docker run --rm \
  -v "$REPORT_DIR:/reports" \
  python:3.11-slim \
  python3 -c "
import json
import csv
import os

json_file = '/reports/$(basename "$JSON_FILE")'
csv_file = '/reports/issues_${TIMESTAMP}.csv'

print(f'Reading: {json_file}')

try:
    with open(json_file) as f:
        data = json.load(f)

    failed_checks = data.get('results', {}).get('failed_checks', [])
    print(f'Found {len(failed_checks)} failed checks')

    with open(csv_file, 'w', newline='') as csvfile:
        fieldnames = ['Check ID', 'Severity', 'Resource', 'File', 'Line', 'Description', 'Guideline']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        
        for result in failed_checks:
            severity = 'UNKNOWN'
            if result.get('check_class'):
                severity = result.get('check_class', '').split('.')[-1]
            
            writer.writerow({
                'Check ID': result.get('check_id', ''),
                'Severity': severity,
                'Resource': result.get('resource', ''),
                'File': result.get('file_path', ''),
                'Line': str(result.get('file_line_range', [''])[0]) if result.get('file_line_range') else '',
                'Description': result.get('check_name', ''),
                'Guideline': result.get('guideline', '')
            })
    
    print(f'✅ CSV generated successfully')
except Exception as e:
    print(f'❌ Error: {e}')
    import traceback
    traceback.print_exc()
"

# Cleanup temp JSON file
rm -f "$JSON_FILE"

if [ -f "$REPORT_DIR/issues_${TIMESTAMP}.csv" ]; then
    echo ""
    echo "✅ CSV Report: $REPORT_DIR/issues_${TIMESTAMP}.csv"
    echo "   $(wc -l < "$REPORT_DIR/issues_${TIMESTAMP}.csv") lines (including header)"
else
    echo "❌ CSV file was not created"
    exit 1
fi