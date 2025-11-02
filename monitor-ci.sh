#!/bin/bash

# 🔍 GitOps CI Pipeline Monitor
# Quick script to check CI/CD pipeline status

echo "🎯 GitOps CI/CD Pipeline Status"
echo "================================"
echo ""

# Check current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "📍 Current Branch: $CURRENT_BRANCH"

# Check latest commit
LATEST_COMMIT=$(git log --oneline -1)
echo "📝 Latest Commit: $LATEST_COMMIT"
echo ""

# Check GitHub Actions (if gh CLI is available)
if command -v gh &> /dev/null; then
    echo "🔄 GitHub Actions Status:"
    gh run list --limit 3
    echo ""

    echo "💡 To view detailed run:"
    echo "gh run view --web"
else
    echo "💡 Install GitHub CLI to monitor runs: https://cli.github.com/"
fi

echo ""
echo "🎯 Expected CI Behavior:"
if [[ "$CURRENT_BRANCH" == "main" ]]; then
    echo "✅ Full validation + Container build & push to registry"
    echo "✅ GitOps repository notification"
    echo "✅ ArgoCD should detect and deploy"
elif [[ "$CURRENT_BRANCH" == "developer" ]]; then
    echo "✅ Full validation pipeline"
    echo "✅ Container build (validation only)"
    echo "❌ NO registry push (correct for dev branch)"
    echo "📋 Next: Create PR to main for deployment"
else
    echo "✅ Full validation pipeline"
    echo "❌ NO registry push (correct for feature branch)"
fi

echo ""
echo "🔗 Useful Commands:"
echo "  gh run list                     # List recent runs"
echo "  gh run view --web              # Open latest run in browser"
echo "  gh pr create                   # Create pull request"
echo "  gh pr view --web              # View PR in browser"
