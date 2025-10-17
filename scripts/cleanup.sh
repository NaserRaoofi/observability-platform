#!/bin/bash

set -e

ENVIRONMENT=${1:-dev}
PROJECT_NAME="observability-enterprise"

echo "🧹 Cleaning up $PROJECT_NAME for environment: $ENVIRONMENT"

# Kill any running port forwards
echo "🛑 Stopping port forwarding..."
if [ -f /tmp/port-forward-pids ]; then
    while read pid; do
        kill $pid 2>/dev/null || true
    done < /tmp/port-forward-pids
    rm -f /tmp/port-forward-pids
fi

# Clean up Kubernetes resources
echo "🗑️  Removing Kubernetes resources..."
kubectl delete -k k8s/overlays/$ENVIRONMENT/ || echo "Some K8s resources might not exist"

# Clean up Helm releases
echo "📦 Removing Helm releases..."
helmfile -e $ENVIRONMENT destroy || echo "Some Helm releases might not exist"

# Clean up namespaces
echo "🏷️  Removing namespaces..."
kubectl delete namespace observability || echo "Namespace might not exist"

# Clean up Terraform resources (optional - uncomment if you want full cleanup)
# echo "☁️  Destroying cloud infrastructure..."
# cd terraform/envs/$ENVIRONMENT
# terraform destroy -auto-approve

# Clean up local files
echo "📁 Cleaning up local files..."
find . -name "*.tfplan" -delete
find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "terraform.tfstate.backup" -delete
find . -name ".terraform.lock.hcl" -delete

# Clean up Docker containers (if running locally)
echo "🐳 Cleaning up Docker containers..."
docker ps -q --filter "label=project=$PROJECT_NAME" | xargs docker stop 2>/dev/null || true
docker ps -aq --filter "label=project=$PROJECT_NAME" | xargs docker rm 2>/dev/null || true

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "⚠️  Note: Cloud infrastructure (EC2, S3, etc.) was NOT destroyed."
echo "   If you want to destroy cloud resources, run:"
echo "   cd terraform/envs/$ENVIRONMENT && terraform destroy"
echo ""
echo "💰 Remember to check AWS costs and clean up unused resources!"
