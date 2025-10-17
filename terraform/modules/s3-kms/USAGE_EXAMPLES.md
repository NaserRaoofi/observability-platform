# S3-KMS Module Usage Examples

## Overview

This module creates S3 buckets with KMS encryption for the observability stack components (Mimir, Loki, Tempo) with proper security, lifecycle management, and cost optimization.

## Features

- **🔐 KMS Encryption** - All buckets encrypted with customer-managed KMS keys
- **📊 Mimir Support** - Optimized for metrics storage with CORS support
- **📋 Loki Support** - Optimized for log chunks with aggressive lifecycle policies
- **🔍 Tempo Support** - Optimized for trace data with medium retention
- **💰 Cost Optimization** - Intelligent lifecycle transitions and storage classes
- **🔒 Security** - Public access blocked, versioning enabled, access logging
- **📈 Monitoring** - SNS notifications for bucket events

## Basic Usage - Mimir Only

```hcl
module "observability_s3" {
  source = "./modules/s3-kms"

  # Environment configuration
  environment  = "prod"
  project_name = "observability"

  # Create only Mimir bucket
  create_mimir_bucket = true
  create_loki_bucket  = false
  create_tempo_bucket = false

  # KMS encryption
  create_kms_key      = true
  enable_key_rotation = true

  # Basic security
  enable_versioning = true

  tags = {
    Environment = "prod"
    Team        = "platform"
  }
}
```

## Full Observability Stack

```hcl
module "observability_s3" {
  source = "./modules/s3-kms"

  # Environment configuration
  environment  = "prod"
  project_name = "observability"

  # Create all buckets
  create_mimir_bucket = true
  create_loki_bucket  = true
  create_tempo_bucket = true

  # KMS encryption with custom settings
  create_kms_key               = true
  enable_key_rotation          = true
  kms_deletion_window_in_days  = 30

  # Security and compliance
  enable_versioning    = true
  enable_access_logging = true

  # Lifecycle management for cost optimization
  enable_lifecycle_management = true

  # Data retention policies
  logs_retention_days   = 365  # 1 year for logs
  traces_retention_days = 90   # 3 months for traces

  # CORS for Mimir web interface
  enable_cors = true
  cors_allowed_origins = [
    "https://mimir.company.com",
    "https://grafana.company.com"
  ]

  # Notifications for monitoring
  enable_notifications = true
  sns_topic_arn        = aws_sns_topic.s3_events.arn

  tags = {
    Environment   = "prod"
    Team          = "platform"
    CostCenter    = "engineering"
    Compliance    = "SOC2"
    BackupPolicy  = "7-years"
  }
}
```

## Development Environment

```hcl
module "observability_s3" {
  source = "./modules/s3-kms"

  # Development configuration
  environment  = "dev"
  project_name = "observability"

  # Minimal setup for development
  create_mimir_bucket = true
  create_loki_bucket  = false
  create_tempo_bucket = false

  # Cost optimization for dev
  create_kms_key = false  # Use default encryption
  existing_kms_key_arn = "alias/aws/s3"

  enable_versioning           = false  # Reduce costs
  enable_lifecycle_management = true
  enable_access_logging       = false

  # Aggressive cleanup for dev data
  logs_retention_days   = 7
  traces_retention_days = 3

  tags = {
    Environment = "dev"
    Purpose     = "development"
    AutoDelete  = "true"
  }
}
```

## High Availability Setup

```hcl
module "observability_s3" {
  source = "./modules/s3-kms"

  environment  = "prod"
  project_name = "observability"

  # Full stack deployment
  create_mimir_bucket = true
  create_loki_bucket  = true
  create_tempo_bucket = true

  # Enhanced security and compliance
  create_kms_key      = true
  enable_key_rotation = true

  enable_versioning           = true
  enable_lifecycle_management = true
  enable_access_logging       = true

  # Cross-region replication for DR
  enable_cross_region_replication = true
  replication_destination_region  = "us-west-2"

  # Object Lock for compliance
  object_lock_enabled = true
  object_lock_configuration = {
    mode  = "GOVERNANCE"
    years = 7
  }

  # Performance optimization
  transfer_acceleration_enabled = true
  intelligent_tiering_enabled   = true

  # Extended retention for compliance
  logs_retention_days   = 2555  # 7 years
  traces_retention_days = 365   # 1 year

  tags = {
    Environment   = "prod"
    Team          = "platform"
    Compliance    = "SOC2"
    DataClass     = "confidential"
    Retention     = "7-years"
  }
}
```

## Custom Bucket Policies

```hcl
module "observability_s3" {
  source = "./modules/s3-kms"

  environment  = "prod"
  project_name = "observability"

  create_mimir_bucket = true
  create_loki_bucket  = true

  # Custom bucket policies for additional security
  bucket_policy_statements = [
    {
      sid    = "DenyInsecureConnections"
      effect = "Deny"
      actions = ["s3:*"]
      resources = ["arn:aws:s3:::*/*"]
      principals = {
        type        = "*"
        identifiers = ["*"]
      }
      condition = [
        {
          test     = "Bool"
          variable = "aws:SecureTransport"
          values   = ["false"]
        }
      ]
    },
    {
      sid    = "AllowVPCEndpointAccess"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:PutObject"
      ]
      resources = ["arn:aws:s3:::*/*"]
      principals = {
        type        = "AWS"
        identifiers = ["*"]
      }
      condition = [
        {
          test     = "StringEquals"
          variable = "aws:sourceVpce"
          values   = ["vpce-1a2b3c4d"]
        }
      ]
    }
  ]
}
```

## Integration with Other Modules

### With DynamoDB Module

```hcl
# S3 buckets
module "observability_s3" {
  source = "./modules/s3-kms"

  environment         = var.environment
  project_name        = var.project_name
  create_mimir_bucket = true
  create_loki_bucket  = var.enable_loki
}

# DynamoDB tables
module "observability_dynamodb" {
  source = "./modules/dynamodb"

  environment         = var.environment
  project_name        = var.project_name
  create_mimir_table  = true
  create_loki_table   = var.enable_loki
}

# IAM roles
module "observability_iam" {
  source = "./modules/iam"

  environment           = var.environment
  project_name          = var.project_name
  eks_oidc_provider_arn = module.eks.oidc_provider_arn

  # Pass bucket ARNs from S3 module
  mimir_s3_bucket_arn = module.observability_s3.mimir_bucket_arn
  loki_s3_bucket_arn  = module.observability_s3.loki_bucket_arn

  # Pass table ARNs from DynamoDB module
  mimir_table_arn = module.observability_dynamodb.mimir_table_arn
  loki_table_arn  = module.observability_dynamodb.loki_table_arn
}
```

## Application Configuration

### Mimir Configuration

```yaml
# mimir-values.yaml
blocks_storage:
  backend: s3
  s3:
    bucket_name: "${module.observability_s3.mimir_bucket_name}"
    region: "${module.observability_s3.mimir_bucket_region}"
    endpoint: "${module.observability_s3.mimir_s3_config.endpoint}"
    sse_config:
      type: "SSE-KMS"
      kms_key_id: "${module.observability_s3.kms_key_arn}"

serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: "${module.observability_iam.mimir_role_arn}"
```

### Loki Configuration

```yaml
# loki-values.yaml
storage_config:
  aws:
    bucketnames: "${module.observability_s3.loki_bucket_name}"
    region: "${module.observability_s3.loki_bucket_region}"
    sse_encryption: true
    kms_encryption_context: "${module.observability_s3.kms_key_arn}"

serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: "${module.observability_iam.loki_role_arn}"
```

### Tempo Configuration

```yaml
# tempo-values.yaml
storage:
  trace:
    backend: s3
    s3:
      bucket: "${module.observability_s3.tempo_bucket_name}"
      region: "${module.observability_s3.tempo_bucket_region}"
      kms_key_id: "${module.observability_s3.kms_key_arn}"

serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: "${module.observability_iam.tempo_role_arn}"
```

## Cost Optimization

### Lifecycle Policy Example

The module automatically configures intelligent lifecycle policies:

```
Day 0-30:   STANDARD (immediate access)
Day 30-90:  STANDARD_IA (less frequent access)
Day 90-365: GLACIER (archival)
Day 365+:   DEEP_ARCHIVE (long-term archival)
```

### Intelligent Tiering

```hcl
module "observability_s3" {
  # ... other configuration ...

  intelligent_tiering_enabled      = true
  intelligent_tiering_filter_prefix = "metrics/"  # Only for metrics data

  # This automatically moves objects between access tiers
  # based on actual access patterns
}
```

## Security Best Practices

### Encryption

- ✅ **Customer-managed KMS keys** with automatic rotation
- ✅ **Bucket-level encryption** for all objects
- ✅ **Versioning** enabled for data protection

### Access Control

- ✅ **Public access blocked** by default
- ✅ **IAM policies** integrated with service roles
- ✅ **VPC endpoints** support through custom policies

### Monitoring

- ✅ **Access logging** to separate bucket
- ✅ **SNS notifications** for bucket events
- ✅ **CloudTrail integration** for API auditing

## Troubleshooting

### Common Issues

1. **KMS Access Denied**

   ```bash
   # Check KMS key policy allows S3 service
   aws kms describe-key --key-id ${module.observability_s3.kms_key_id}
   ```

2. **Bucket Access Issues**

   ```bash
   # Verify bucket policy
   aws s3api get-bucket-policy --bucket ${module.observability_s3.mimir_bucket_name}
   ```

3. **Lifecycle Policy Not Working**
   ```bash
   # Check lifecycle configuration
   aws s3api get-bucket-lifecycle-configuration --bucket ${module.observability_s3.mimir_bucket_name}
   ```

### Monitoring Commands

```bash
# Check bucket metrics
aws s3api get-bucket-metrics-configuration --bucket ${bucket_name}

# List lifecycle rules
aws s3api get-bucket-lifecycle-configuration --bucket ${bucket_name}

# Check encryption configuration
aws s3api get-bucket-encryption --bucket ${bucket_name}
```
