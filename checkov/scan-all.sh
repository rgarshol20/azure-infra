#!/bin/bash
# Scan everything and generate all reports

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "🔍 Running complete security scan of repository..."
echo ""

# Run all scans
"$SCRIPT_DIR/scan.sh" .
"$SCRIPT_DIR/scan-html.sh" .
"$SCRIPT_DIR/scan-csv.sh" .

echo ""
echo "✅ All scans complete! Reports:"
ls -lh "$SCRIPT_DIR/reports/"