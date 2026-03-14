#!/bin/bash
# Checkov scanner with multiple report formats

SCAN_DIR="${1:-.}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPORT_DIR="$SCRIPT_DIR/reports"

# Create reports directory
mkdir -p "$REPORT_DIR"

echo "🔍 Running Checkov scan on: $SCAN_DIR"
echo "📊 Reports will be saved to: $REPORT_DIR"
echo ""

# Run Checkov with multiple output formats
docker run --rm \
  -v "$(pwd):/scan" \
  -v "$REPORT_DIR:/reports" \
  checkov:local \
  -d "/scan/${SCAN_DIR}" \
  --skip-path decommission \
  --framework terraform \
  --check CKV_AZURE_*,CKV_AWS_* \
  --output cli \
  --output json \
  --output-file-path /reports \
  --repo-id "azure-dde-infra" \
  --soft-fail

echo ""
echo "✅ Scan complete! Reports generated:"
ls -lh "$REPORT_DIR"