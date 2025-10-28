# Development Environment Configuration
# Complete observability stack for development with cost optimization

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
      Owner       = "dev-team"
    }
  }
}

# Local values for development environment
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Owner       = "dev-team"
    CostCenter  = "development"
  }
}

# ==========================================
# DynamoDB Module - Tables for Indexing
# ==========================================
module "observability_dynamodb" {
  source = "../../modules/dynamodb"

  # Environment configuration
  environment  = var.environment
  project_name = var.project_name

  # Enable tables for development testing
  create_mimir_table = var.create_mimir_table
  create_loki_table  = var.create_loki_table

  # Cost-effective configuration for dev
  billing_mode = "PAY_PER_REQUEST" # No provisioned capacity needed

  # Security (basic for dev)
  server_side_encryption_enabled = true
  point_in_time_recovery_enabled = false # Disabled for cost savings in dev

  # No autoscaling needed with PAY_PER_REQUEST
  autoscaling_enabled = false

  # Tags
  tags = local.common_tags
}

# ==========================================
# S3-KMS Module - Storage with Encryption
# ==========================================
module "observability_s3" {
  source = "../../modules/s3-kms"

  # Environment configuration
  environment  = var.environment
  project_name = var.project_name

  # Enable buckets based on services being tested
  create_mimir_bucket = var.create_mimir_bucket
  create_loki_bucket  = var.create_loki_bucket
  create_tempo_bucket = var.create_tempo_bucket

  # KMS encryption (basic for dev)
  create_kms_key      = var.create_kms_key
  enable_key_rotation = false # Disabled for cost savings in dev

  # Tags
  tags = local.common_tags
}

# ==========================================
# IAM Module - IRSA Roles and Policies
# ==========================================
module "observability_iam" {
  source = "../../modules/iam"

  # Environment configuration
  environment = var.environment

  # Required: EKS OIDC provider ARN
  eks_oidc_provider_arn = var.eks_oidc_provider_arn

  # Service account namespace
  monitoring_namespace = var.monitoring_namespace

  # Required: DynamoDB table ARNs
  mimir_table_arn = module.observability_dynamodb.mimir_table_arn
  loki_table_arn  = var.create_loki_table ? module.observability_dynamodb.loki_table_arn : null

  # Required: S3 bucket ARNs
  mimir_s3_bucket_arn = module.observability_s3.mimir_bucket_arn
  loki_s3_bucket_arn  = var.create_loki_bucket ? module.observability_s3.loki_bucket_arn : null
  tempo_s3_bucket_arn = var.create_tempo_bucket ? module.observability_s3.tempo_bucket_arn : null

  # Feature flags
  create_loki_resources    = var.create_loki_role
  create_grafana_resources = var.create_grafana_role
  create_tempo_resources   = var.create_tempo_role

  # Tags
  tags = local.common_tags
}

# ==========================================
# Grafana Module - Dashboards and Configuration
# ==========================================
module "observability_grafana" {
  source = "../../modules/grafana"

  # Dashboard configuration
  enable_dashboards    = var.enable_grafana_dashboards
  grafana_org_id      = var.grafana_org_id
  grafana_folder_uid  = "observability-${var.environment}"

  # Data source endpoints (adjust based on your setup)
  prometheus_endpoint   = var.prometheus_endpoint
  alertmanager_endpoint = var.alertmanager_endpoint

  # Workspace configuration (for managed Grafana)
  create_workspace      = var.create_grafana_workspace
  workspace_name        = "${var.project_name}-${var.environment}"
  workspace_description = "Observability platform Grafana workspace for ${var.environment}"
  workspace_role_arn    = var.create_grafana_role ? module.observability_iam.grafana_role_arn : null

  # Tags
  tags = local.common_tags
}
