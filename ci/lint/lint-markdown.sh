#!/bin/bash

set -e

echo "📝 Running Markdown linting..."

# Find all Markdown files
MD_FILES=$(find . -name "*.md" | grep -v ".git" | grep -v node_modules)

if [ -z "$MD_FILES" ]; then
    echo "No Markdown files found"
    exit 0
fi

# Run markdownlint
echo "Found Markdown files:"
echo "$MD_FILES"

markdownlint -c ci/lint/.markdownlint.json $MD_FILES

echo "✅ Markdown linting completed successfully"
