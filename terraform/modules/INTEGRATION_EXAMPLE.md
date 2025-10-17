# Complete Observability Stack Integration Example

This example demonstrates how to deploy the complete observability stack using all three modules together.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Production Deployment                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   EKS Cluster                    AWS Services                   │
│   ┌─────────────┐               ┌─────────────────┐            │
│   │             │               │                 │            │
│   │ ┌─────────┐ │   IRSA        │ ┌─────────────┐ │            │
│   │ │ Mimir   │ │──────────────►│ │ DynamoDB    │ │            │
│   │ │ Pod     │ │               │ │ Tables      │ │            │
│   │ └─────────┘ │               │ └─────────────┘ │            │
│   │             │               │                 │            │
│   │ ┌─────────┐ │               │ ┌─────────────┐ │            │
│   │ │ Loki    │ │──────────────►│ │ S3 Buckets  │ │            │
│   │ │ Pod     │ │               │ │ + KMS Keys  │ │            │
│   │ └─────────┘ │               │ └─────────────┘ │            │
│   │             │               │                 │            │
│   │ ┌─────────┐ │               │ ┌─────────────┐ │            │
│   │ │ Tempo   │ │──────────────►│ │ IAM Roles   │ │            │
│   │ │ Pod     │ │               │ │ & Policies  │ │            │
│   │ └─────────┘ │               │ └─────────────┘ │            │
│   │             │               │                 │            │
│   └─────────────┘               └─────────────────┘            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Complete Stack Deployment

### 1. Production Environment

```hcl
# terraform/envs/prod/main.tf

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "production"
      Project     = "observability-enterprise"
      ManagedBy   = "terraform"
      Owner       = "platform-team"
    }
  }
}

locals {
  environment = "prod"
  project     = "observability"

  # Common tags for all resources
  common_tags = {
    Environment = local.environment
    Project     = local.project
    ManagedBy   = "terraform"
    Owner       = "platform-team"
  }
}

# ==========================================
# DynamoDB Module - Tables for Indexing
# ==========================================
module "observability_dynamodb" {
  source = "../../modules/dynamodb"

  # Environment configuration
  environment  = local.environment
  project_name = local.project

  # Enable tables for services we're deploying
  create_mimir_tables = true
  create_loki_tables  = true

  # Performance configuration
  billing_mode = "PAY_PER_REQUEST"  # Cost-effective for variable workloads

  # Security
  point_in_time_recovery_enabled = true
  deletion_protection_enabled    = true

  # Tags
  tags = local.common_tags
}

# ==========================================
# S3-KMS Module - Storage with Encryption
# ==========================================
module "observability_s3" {
  source = "../../modules/s3-kms"

  # Environment configuration
  environment  = local.environment
  project_name = local.project

  # Enable buckets for services we're deploying
  create_mimir_bucket = true
  create_loki_bucket  = true
  create_tempo_bucket = true

  # KMS encryption
  create_kms_key      = true
  enable_key_rotation = true
  kms_key_description = "Observability data encryption key for ${local.environment}"

  # Lifecycle management for cost optimization
  enable_lifecycle_management = true

  # Retention policies (adjust based on compliance requirements)
  metrics_retention_days = 2555  # ~7 years for metrics
  logs_retention_days    = 365   # 1 year for logs
  traces_retention_days  = 90    # 90 days for traces

  # Performance optimizations
  enable_transfer_acceleration = true
  enable_intelligent_tiering   = true

  # Security hardening
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Monitoring
  enable_cloudwatch_metrics = true
  enable_sns_notifications  = true

  # Tags
  tags = local.common_tags
}

# ==========================================
# IAM Module - IRSA Roles and Policies
# ==========================================
module "observability_iam" {
  source = "../../modules/iam"

  # EKS cluster configuration
  cluster_name = var.eks_cluster_name
  environment  = local.environment

  # Service account namespaces
  monitoring_namespace = "monitoring"
  logging_namespace    = "logging"
  tracing_namespace    = "tracing"

  # Cross-module resource references
  # DynamoDB tables
  mimir_dynamodb_table_arn = module.observability_dynamodb.mimir_table_arn
  loki_dynamodb_table_arn  = module.observability_dynamodb.loki_table_arn

  # S3 buckets
  mimir_s3_bucket_arn = module.observability_s3.mimir_bucket_arn
  loki_s3_bucket_arn  = module.observability_s3.loki_bucket_arn
  tempo_s3_bucket_arn = module.observability_s3.tempo_bucket_arn

  # KMS key for encryption/decryption
  kms_key_arn = module.observability_s3.kms_key_arn

  # Feature flags
  create_mimir_role  = true
  create_loki_role   = true
  create_grafana_role = true
  create_tempo_role  = true

  # Tags
  tags = local.common_tags
}

# ==========================================
# Outputs for Integration
# ==========================================
output "dynamodb_outputs" {
  description = "DynamoDB module outputs"
  value = {
    mimir_table_name = module.observability_dynamodb.mimir_table_name
    mimir_table_arn  = module.observability_dynamodb.mimir_table_arn
    loki_table_name  = module.observability_dynamodb.loki_table_name
    loki_table_arn   = module.observability_dynamodb.loki_table_arn
  }
}

output "s3_outputs" {
  description = "S3 module outputs"
  value = {
    mimir_bucket_name = module.observability_s3.mimir_bucket_name
    mimir_bucket_arn  = module.observability_s3.mimir_bucket_arn
    loki_bucket_name  = module.observability_s3.loki_bucket_name
    loki_bucket_arn   = module.observability_s3.loki_bucket_arn
    tempo_bucket_name = module.observability_s3.tempo_bucket_name
    tempo_bucket_arn  = module.observability_s3.tempo_bucket_arn
    kms_key_arn       = module.observability_s3.kms_key_arn
  }
}

output "iam_outputs" {
  description = "IAM module outputs"
  value = {
    mimir_role_arn  = module.observability_iam.mimir_role_arn
    loki_role_arn   = module.observability_iam.loki_role_arn
    grafana_role_arn = module.observability_iam.grafana_role_arn
    tempo_role_arn  = module.observability_iam.tempo_role_arn
  }
}

# Integration summary for easy reference
output "observability_stack_summary" {
  description = "Complete observability stack configuration summary"
  value = {
    environment = local.environment

    # Storage layer
    storage = {
      mimir_dynamodb_table = module.observability_dynamodb.mimir_table_name
      mimir_s3_bucket     = module.observability_s3.mimir_bucket_name
      loki_dynamodb_table = module.observability_dynamodb.loki_table_name
      loki_s3_bucket      = module.observability_s3.loki_bucket_name
      tempo_s3_bucket     = module.observability_s3.tempo_bucket_name
      kms_key_id          = module.observability_s3.kms_key_id
    }

    # Security layer
    security = {
      mimir_service_account_role  = module.observability_iam.mimir_role_arn
      loki_service_account_role   = module.observability_iam.loki_role_arn
      grafana_service_account_role = module.observability_iam.grafana_role_arn
      tempo_service_account_role  = module.observability_iam.tempo_role_arn
    }

    # Configuration for Kubernetes deployments
    kubernetes_annotations = {
      mimir_service_account  = "eks.amazonaws.com/role-arn: ${module.observability_iam.mimir_role_arn}"
      loki_service_account   = "eks.amazonaws.com/role-arn: ${module.observability_iam.loki_role_arn}"
      grafana_service_account = "eks.amazonaws.com/role-arn: ${module.observability_iam.grafana_role_arn}"
      tempo_service_account  = "eks.amazonaws.com/role-arn: ${module.observability_iam.tempo_role_arn}"
    }
  }
}
```

### 2. Variables File

```hcl
# terraform/envs/prod/variables.tf

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "enable_cost_optimization" {
  description = "Enable aggressive cost optimization features"
  type        = bool
  default     = true
}

variable "compliance_retention_days" {
  description = "Data retention days for compliance"
  type        = number
  default     = 2555  # 7 years
}
```

### 3. Terraform Configuration

```hcl
# terraform/envs/prod/terraform.tfvars

aws_region         = "us-west-2"
eks_cluster_name   = "prod-observability-cluster"
enable_cost_optimization = true
compliance_retention_days = 2555
```

## Deployment Steps

### 1. Initialize Terraform

```bash
cd terraform/envs/prod
terraform init
```

### 2. Plan Deployment

```bash
terraform plan -var-file="terraform.tfvars"
```

### 3. Deploy Infrastructure

```bash
terraform apply -var-file="terraform.tfvars"
```

### 4. Verify Resources

```bash
# Check DynamoDB tables
aws dynamodb list-tables --region us-west-2

# Check S3 buckets
aws s3 ls

# Check IAM roles
aws iam list-roles --query 'Roles[?contains(RoleName, `observability`)]'
```

## Kubernetes Integration

### Service Account Configuration

```yaml
# k8s/mimir-service-account.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: mimir
  namespace: monitoring
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::ACCOUNT:role/observability-prod-mimir-role"
---
# k8s/loki-service-account.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: loki
  namespace: logging
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::ACCOUNT:role/observability-prod-loki-role"
---
# k8s/tempo-service-account.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tempo
  namespace: tracing
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::ACCOUNT:role/observability-prod-tempo-role"
```

### Mimir Configuration Example

```yaml
# Use the Terraform outputs in your Helm values
mimir:
  storage:
    backend: s3
    s3:
      bucket_name: "observability-prod-mimir"
      region: "us-west-2"

  indexGateway:
    storage:
      type: dynamodb
      dynamodb:
        table_name: "observability-prod-mimir"
        region: "us-west-2"

  serviceAccount:
    create: false
    name: mimir
```

## Monitoring and Alerts

### CloudWatch Dashboard

```json
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", "observability-prod-mimir"],
          ["AWS/S3", "BucketSizeBytes", "BucketName", "observability-prod-mimir"]
        ],
        "period": 300,
        "stat": "Sum",
        "region": "us-west-2",
        "title": "Observability Storage Metrics"
      }
    }
  ]
}
```

## Cost Optimization

### Expected Monthly Costs

- **DynamoDB**: $50-200 (depends on read/write patterns)
- **S3 Storage**: $100-500 (depends on data volume and lifecycle)
- **KMS**: $1-5 (key usage)
- **Data Transfer**: $10-100 (depends on cross-AZ traffic)

**Total**: ~$160-800/month for production workload

### Cost Reduction Strategies

1. **Lifecycle Policies**: Automatic transition to cheaper storage classes
2. **Intelligent Tiering**: S3 automatically optimizes storage costs
3. **Pay-per-Request**: DynamoDB billing only for actual usage
4. **Retention Policies**: Automatic cleanup of old data

## Troubleshooting

### Common Issues

1. **IRSA Trust Relationship Errors**

```bash
# Verify OIDC provider exists
aws iam list-open-id-connect-providers

# Check trust policy
aws iam get-role --role-name observability-prod-mimir-role
```

2. **S3 Access Denied**

```bash
# Test bucket access
aws s3 ls s3://observability-prod-mimir --region us-west-2

# Check bucket policy
aws s3api get-bucket-policy --bucket observability-prod-mimir
```

3. **DynamoDB Throttling**

```bash
# Check table metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ThrottledRequests \
  --dimensions Name=TableName,Value=observability-prod-mimir \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Sum
```

## Security Considerations

### Encryption

- ✅ **DynamoDB**: Encryption at rest with AWS managed keys
- ✅ **S3**: Customer-managed KMS keys with rotation
- ✅ **Transit**: All connections use TLS 1.2+

### Access Control

- ✅ **Least Privilege**: Each service has minimal required permissions
- ✅ **IRSA**: Secure token exchange without long-lived credentials
- ✅ **Resource-Based**: Bucket policies restrict access to specific roles

### Monitoring

- ✅ **CloudTrail**: All API calls logged
- ✅ **Access Logs**: S3 bucket access logging enabled
- ✅ **Metrics**: CloudWatch metrics for all services

This complete integration example provides a production-ready observability stack with security, cost optimization, and operational best practices built in.
