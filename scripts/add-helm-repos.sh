#!/bin/bash

# Optional: Add Helm repositories locally for direct helm CLI access
# This is NOT required for helmfile deployment, but useful for manual operations

echo "Adding Helm repositories for direct CLI access..."

# Add repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts

# Update repositories
helm repo update

echo "✓ Helm repositories added locally"
echo ""
echo "Available charts:"
echo "- helm search repo grafana/loki"
echo "- helm search repo grafana/promtail"
echo "- helm search repo grafana/mimir-distributed"
echo ""
echo "Note: These are automatically managed by helmfile during deployment"
