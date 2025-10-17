#!/bin/bash

set -e

echo "📄 Running JSON linting..."

# Find all JSON files
JSON_FILES=$(find . -name "*.json" | grep -v ".git" | grep -v node_modules)

if [ -z "$JSON_FILES" ]; then
    echo "No JSON files found"
    exit 0
fi

echo "Found JSON files:"
echo "$JSON_FILES"

# Validate JSON syntax
for file in $JSON_FILES; do
    echo "Validating $file..."
    if ! python -m json.tool "$file" > /dev/null; then
        echo "❌ Invalid JSON syntax in $file"
        exit 1
    fi
done

echo "✅ JSON linting completed successfully"
