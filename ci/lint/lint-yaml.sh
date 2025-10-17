#!/bin/bash

set -e

echo "🧹 Running YAML linting..."

# Find all YAML files
YAML_FILES=$(find . -name "*.yaml" -o -name "*.yml" | grep -v ".git" | head -20)

if [ -z "$YAML_FILES" ]; then
    echo "No YAML files found"
    exit 0
fi

# Run yamllint
echo "Found YAML files:"
echo "$YAML_FILES"

yamllint -c ci/lint/.yamllint.yml $YAML_FILES

echo "✅ YAML linting completed successfully"
