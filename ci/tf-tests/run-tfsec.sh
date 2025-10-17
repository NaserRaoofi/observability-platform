#!/bin/bash

# Terraform security scan using tfsec
echo "🔍 Running Terraform security scan..."

cd "$(dirname "$0")/../../terraform"

# Run tfsec with configuration
tfsec . --config-file ../ci/tf-tests/.tfsec.yml --format json --out tfsec-results.json

# Check for high/critical issues
CRITICAL_ISSUES=$(jq '[.results[] | select(.severity == "CRITICAL")] | length' tfsec-results.json)
HIGH_ISSUES=$(jq '[.results[] | select(.severity == "HIGH")] | length' tfsec-results.json)

echo "Critical issues found: $CRITICAL_ISSUES"
echo "High issues found: $HIGH_ISSUES"

# Fail if critical issues found
if [ "$CRITICAL_ISSUES" -gt 0 ]; then
    echo "❌ Critical security issues found. Please fix them before proceeding."
    exit 1
fi

# Warn if high issues found
if [ "$HIGH_ISSUES" -gt 0 ]; then
    echo "⚠️  High severity issues found. Consider fixing them."
fi

echo "✅ Terraform security scan completed"
