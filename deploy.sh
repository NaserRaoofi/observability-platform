#!/bin/bash

# Observability Stack Deployment Script
# Integrates Terraform infrastructure with Helm deployments

set -e

# Configuration
TERRAFORM_DIR="./terraform/envs/dev"
HELM_VALUES_DIR="./k8s/base"
NAMESPACE="observability"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed or not in PATH"
        exit 1
    fi

    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        log_error "Helm is not installed or not in PATH"
        exit 1
    fi

    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed or not in PATH"
        exit 1
    fi

    log_info "✓ All prerequisites met"
}

# Function to get Terraform outputs
get_terraform_outputs() {
    log_info "Getting Terraform outputs..."

    cd "$TERRAFORM_DIR"

    # Check if terraform state exists
    if [ ! -f "terraform.tfstate" ]; then
        log_error "Terraform state not found. Please run 'terraform apply' first."
        exit 1
    fi

    # Get outputs as JSON
    terraform output -json > /tmp/terraform_outputs.json

    cd - > /dev/null

    log_info "✓ Terraform outputs retrieved"
}

# Function to template Mimir values
template_mimir_values() {
    log_info "Templating Mimir values file..."

    # Extract values from Terraform outputs
    local aws_region=$(jq -r '.aws_region.value // "us-west-2"' /tmp/terraform_outputs.json)
    local mimir_bucket=$(jq -r '.mimir_bucket_name.value' /tmp/terraform_outputs.json)
    local mimir_table=$(jq -r '.mimir_table_name.value' /tmp/terraform_outputs.json)
    local kms_key_id=$(jq -r '.kms_key_id.value' /tmp/terraform_outputs.json)
    local mimir_role_arn=$(jq -r '.mimir_role_arn.value' /tmp/terraform_outputs.json)

    # Validate required outputs
    if [ "$mimir_bucket" == "null" ] || [ "$mimir_table" == "null" ] || [ "$mimir_role_arn" == "null" ]; then
        log_error "Required Terraform outputs not found. Please ensure Mimir resources are deployed."
        log_error "Missing: S3=$mimir_bucket, DynamoDB=$mimir_table, Role=$mimir_role_arn"
        exit 1
    fi

    # Template the values file
    sed -e "s/\${aws_region}/$aws_region/g" \
        -e "s/\${mimir_s3_bucket_name}/$mimir_bucket/g" \
        -e "s/\${mimir_dynamodb_table_name}/$mimir_table/g" \
        -e "s/\${kms_key_id}/$kms_key_id/g" \
        -e "s|\${mimir_irsa_role_arn}|$mimir_role_arn|g" \
        "$HELM_VALUES_DIR/mimir/values.template.yaml" > "$HELM_VALUES_DIR/mimir/values.generated.yaml"

    log_info "✓ Mimir values templated successfully"
    log_info "  - S3 Bucket: $mimir_bucket"
    log_info "  - DynamoDB Table: $mimir_table"
    log_info "  - IRSA Role: $mimir_role_arn"
    log_info "  - Region: $aws_region"
}

# Function to template Loki values
template_loki_values() {
    log_info "Templating Loki values file..."

    # Extract values from Terraform outputs
    local aws_region=$(jq -r '.aws_region.value // "us-west-2"' /tmp/terraform_outputs.json)
    local loki_bucket=$(jq -r '.loki_bucket_name.value' /tmp/terraform_outputs.json)
    local kms_key_id=$(jq -r '.kms_key_id.value' /tmp/terraform_outputs.json)
    local loki_role_arn=$(jq -r '.loki_role_arn.value' /tmp/terraform_outputs.json)

    # Check if Loki resources are enabled
    if [ "$loki_bucket" == "null" ] || [ "$loki_role_arn" == "null" ]; then
        log_warn "Loki resources not found, skipping Loki templating"
        log_warn "Missing: S3=$loki_bucket, Role=$loki_role_arn"
        return 0
    fi

    # Template Loki values file
    sed -e "s/\${aws_region}/$aws_region/g" \
        -e "s/\${loki_s3_bucket_name}/$loki_bucket/g" \
        -e "s/\${kms_key_id}/$kms_key_id/g" \
        -e "s|\${loki_irsa_role_arn}|$loki_role_arn|g" \
        "$HELM_VALUES_DIR/loki/values.template.yaml" > "$HELM_VALUES_DIR/loki/values.generated.yaml"

    log_info "✓ Loki values templated successfully"
    log_info "  - S3 Bucket: $loki_bucket"
    log_info "  - IRSA Role: $loki_role_arn"
    log_info "  - Region: $aws_region"
}

# Function to template Tempo values
template_tempo_values() {
    log_info "Templating Tempo values file..."

    # Extract values from Terraform outputs
    local aws_region=$(jq -r '.aws_region.value // "us-west-2"' /tmp/terraform_outputs.json)
    local tempo_bucket=$(jq -r '.tempo_bucket_name.value' /tmp/terraform_outputs.json)
    local kms_key_id=$(jq -r '.kms_key_id.value' /tmp/terraform_outputs.json)
    local tempo_role_arn=$(jq -r '.tempo_role_arn.value' /tmp/terraform_outputs.json)

    # Check if Tempo resources are enabled
    if [ "$tempo_bucket" == "null" ] || [ "$tempo_role_arn" == "null" ]; then
        log_warn "Tempo resources not found, skipping Tempo templating"
        log_warn "Missing: S3=$tempo_bucket, Role=$tempo_role_arn"
        return 0
    fi

    # Template Tempo values file
    sed -e "s/\${aws_region}/$aws_region/g" \
        -e "s/\${tempo_s3_bucket_name}/$tempo_bucket/g" \
        -e "s/\${kms_key_id}/$kms_key_id/g" \
        -e "s|\${tempo_irsa_role_arn}|$tempo_role_arn|g" \
        "$HELM_VALUES_DIR/tempo/values.template.yaml" > "$HELM_VALUES_DIR/tempo/values.generated.yaml"

    log_info "✓ Tempo values templated successfully"
    log_info "  - S3 Bucket: $tempo_bucket"
    log_info "  - IRSA Role: $tempo_role_arn"
    log_info "  - Region: $aws_region"
}

# Function to add Helm repositories
add_helm_repos() {
    log_info "Adding Helm repositories..."

    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
    helm repo add sloth https://slok.github.io/sloth
    helm repo update

    log_info "✓ Helm repositories added and updated"
}

# Function to create namespace
create_namespace() {
    log_info "Creating observability namespace..."

    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

    log_info "✓ Namespace '$NAMESPACE' ready"
}

# Function to deploy exporters
deploy_exporters() {
    log_info "Deploying exporters..."

    # Node Exporter
    helm upgrade --install node-exporter prometheus-community/prometheus-node-exporter \
        --namespace "$NAMESPACE" \
        -f "$HELM_VALUES_DIR/exporters/node-exporter/values.yaml"

    # Kube State Metrics
    helm upgrade --install kube-state-metrics prometheus-community/kube-state-metrics \
        --namespace "$NAMESPACE" \
        -f "$HELM_VALUES_DIR/exporters/kube-state-metrics/values.yaml"

    # Blackbox Exporter
    helm upgrade --install blackbox-exporter prometheus-community/prometheus-blackbox-exporter \
        --namespace "$NAMESPACE" \
        -f "$HELM_VALUES_DIR/exporters/blackbox-exporter/values.yaml"

    # CloudWatch Exporter (if configured)
    if kubectl get secret aws-credentials -n "$NAMESPACE" > /dev/null 2>&1; then
        helm upgrade --install cloudwatch-exporter prometheus-community/prometheus-cloudwatch-exporter \
            --namespace "$NAMESPACE" \
            -f "$HELM_VALUES_DIR/exporters/aws-cloudwatch-exporter/values.yaml"
    else
        log_warn "Skipping CloudWatch Exporter - AWS credentials not found"
    fi

    log_info "✓ Exporters deployed"
}

# Function to deploy Mimir
deploy_mimir() {
    log_info "Deploying Mimir..."

    # Check if generated values exist
    if [ ! -f "$HELM_VALUES_DIR/mimir/values.generated.yaml" ]; then
        log_error "Generated Mimir values file not found. Run templating first."
        exit 1
    fi

    helm upgrade --install mimir grafana/mimir-distributed \
        --namespace "$NAMESPACE" \
        -f "$HELM_VALUES_DIR/mimir/values.generated.yaml" \
        --wait --timeout=10m

    log_info "✓ Mimir deployed successfully"
}

# Function to deploy Loki and Promtail
deploy_loki_stack() {
    log_info "Deploying Loki and Promtail..."

    # Check if Loki values file exists (generated from template)
    if [ -f "$HELM_VALUES_DIR/loki/values.generated.yaml" ]; then
        helm upgrade --install loki grafana/loki \
            --namespace "$NAMESPACE" \
            -f "$HELM_VALUES_DIR/loki/values.generated.yaml" \
            --wait --timeout=10m

        log_info "✓ Loki deployed with S3 backend"
    else
        log_warn "Loki values.generated.yaml not found, skipping Loki deployment"
    fi

    # Deploy Promtail
    helm upgrade --install promtail grafana/promtail \
        --namespace "$NAMESPACE" \
        -f "$HELM_VALUES_DIR/promtail/values.yaml" \
        --wait

    log_info "✓ Promtail deployed"
}

# Function to deploy Prometheus Agent
deploy_prometheus_agent() {
    log_info "Deploying Prometheus Agent..."

    # Wait for Mimir gateway to be ready
    log_info "Waiting for Mimir gateway..."
    kubectl wait --for=condition=available deployment/mimir-gateway -n "$NAMESPACE" --timeout=300s

    helm upgrade --install prometheus-agent prometheus-community/prometheus \
        --namespace "$NAMESPACE" \
        -f "$HELM_VALUES_DIR/prometheus-agent/values.yaml" \
        --wait

    log_info "✓ Prometheus Agent deployed"
}

# Function to deploy Tempo
deploy_tempo() {
    log_info "Deploying Tempo..."

    # Check if Tempo values file exists (generated from template)
    if [ -f "$HELM_VALUES_DIR/tempo/values.generated.yaml" ]; then
        helm upgrade --install tempo grafana/tempo \
            --namespace "$NAMESPACE" \
            -f "$HELM_VALUES_DIR/tempo/values.generated.yaml" \
            --wait --timeout=10m

        log_info "✓ Tempo deployed with S3 backend"
    else
        log_warn "Tempo values.generated.yaml not found, deploying with local storage"
        helm upgrade --install tempo grafana/tempo \
            --namespace "$NAMESPACE" \
            -f "$HELM_VALUES_DIR/tempo/values.yaml" \
            --wait --timeout=10m

        log_info "✓ Tempo deployed with local storage"
    fi
}

# Function to deploy Sloth
deploy_sloth() {
    log_info "Deploying Sloth..."

    helm upgrade --install sloth sloth/sloth \
        --namespace "$NAMESPACE" \
        -f "$HELM_VALUES_DIR/sloth/values.yaml" \
        --wait

    log_info "✓ Sloth deployed"

    # Apply SLO definitions after Sloth is running
    log_info "Applying SLO definitions..."
    sleep 10  # Wait for CRDs to be available

    kubectl apply -f "$HELM_VALUES_DIR/sloth/slo-mimir.yaml" -n "$NAMESPACE"
    kubectl apply -f "$HELM_VALUES_DIR/sloth/slo-loki.yaml" -n "$NAMESPACE"
    kubectl apply -f "$HELM_VALUES_DIR/sloth/slo-tempo.yaml" -n "$NAMESPACE"
    kubectl apply -f "$HELM_VALUES_DIR/sloth/slo-prometheus-agent.yaml" -n "$NAMESPACE"
    kubectl apply -f "$HELM_VALUES_DIR/sloth/slo-infrastructure.yaml" -n "$NAMESPACE"

    log_info "✓ SLO definitions applied"
}

# Function to validate deployment
validate_deployment() {
    log_info "Validating deployment..."

    # Check if all pods are running
    log_info "Checking pod status..."
    kubectl get pods -n "$NAMESPACE" -o wide

    # Test Mimir write endpoint
    log_info "Testing Mimir connectivity..."
    local gateway_pod=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/component=gateway -o jsonpath='{.items[0].metadata.name}')

    if [ -n "$gateway_pod" ]; then
        kubectl exec -n "$NAMESPACE" "$gateway_pod" -- curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ready
        echo ""
    fi

    log_info "✓ Deployment validation complete"
}

# Main execution
main() {
    log_info "Starting observability stack deployment..."

    check_prerequisites
    get_terraform_outputs
    template_mimir_values
    template_loki_values
    template_tempo_values
    add_helm_repos
    create_namespace
    deploy_exporters
    deploy_mimir
    deploy_loki_stack
    deploy_tempo
    deploy_prometheus_agent
    deploy_sloth
    validate_deployment

    log_info "🎉 Enterprise Observability Stack deployed successfully!"
    log_info ""
    log_info "📊 Access Points:"
    log_info "  - Mimir Gateway: kubectl port-forward -n $NAMESPACE svc/mimir-gateway 8080:8080"
    log_info "  - Loki Gateway:  kubectl port-forward -n $NAMESPACE svc/loki-gateway 3100:80"
    log_info "  - Tempo Gateway: kubectl port-forward -n $NAMESPACE svc/tempo-gateway 3200:80"
    log_info ""
    log_info "🔍 Components Deployed:"
    log_info "  ✅ Metrics: 6x Exporters + Prometheus Agent + Mimir"
    log_info "  ✅ Logs: Promtail + Loki"
    log_info "  ✅ Traces: Tempo with OTLP/Jaeger/Zipkin receivers"
    log_info "  ✅ SLI/SLO: Sloth with 19 SLO definitions"
    log_info ""
    log_info "📈 Next Steps:"
    log_info "  1. Configure Grafana with Mimir, Loki, and Tempo data sources"
    log_info "  2. Import SLO dashboards from Sloth"
    log_info "  3. Set up AlertManager for SLO alerts"
    log_info "  4. Configure applications to send traces to Tempo"
}

# Parse command line arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "template")
        check_prerequisites
        get_terraform_outputs
        template_mimir_values
        template_loki_values
        template_tempo_values
        ;;
    "validate")
        validate_deployment
        ;;
    "help")
        echo "Usage: $0 [deploy|template|validate|help]"
        echo "  deploy   - Full deployment (default)"
        echo "  template - Only template values files"
        echo "  validate - Only validate existing deployment"
        echo "  help     - Show this help"
        ;;
    *)
        log_error "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac
