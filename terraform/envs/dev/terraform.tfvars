# Development Environment Configuration

# ===============================================================================
# CORE CONFIGURATION
# ===============================================================================
aws_region   = "us-west-2"
environment  = "dev"
project_name = "observability"

# ===============================================================================
# EKS CLUSTER CONFIGURATION
# Replace these with your actual EKS cluster details
# ===============================================================================
eks_cluster_name      = "dev-observability-cluster"
eks_oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/EXAMPLE12345"

# ===============================================================================
# KUBERNETES NAMESPACES
# ===============================================================================
monitoring_namespace = "monitoring"
logging_namespace    = "logging"
tracing_namespace    = "tracing"

# ===============================================================================
# DEVELOPMENT SERVICES ENABLEMENT
# Enable only what you need for development to save costs
# ===============================================================================

# DynamoDB Tables
create_mimir_table = true # Enable for metrics development
create_loki_table  = true # Enable for logs development

# S3 Buckets
create_mimir_bucket = true  # Enable for metrics storage
create_loki_bucket  = true  # Enable for logs storage
create_tempo_bucket = false # Disable to save costs (enable when testing traces)

# KMS Encryption
create_kms_key = true # Enable encryption for security

# IAM Roles
create_mimir_role   = true  # Enable for Mimir development
create_loki_role    = true  # Enable for Loki development
create_grafana_role = true  # Enable for dashboard access
create_tempo_role   = false # Disable to save costs (enable when testing traces)

# ===============================================================================
# ADDITIONAL TAGS
# ===============================================================================
additional_tags = {
  CostCenter = "development"
  Team       = "platform"
  Purpose    = "observability-development"
}
