# S3 + KMS Module for Observability Stack

This Terraform module creates secure S3 buckets with KMS encryption for observability services (Mimir, Loki, Tempo) with comprehensive lifecycle management and cost optimization.

## Features

- **🔐 KMS Encryption** - Customer-managed keys with automatic rotation
- **📊 Mimir Storage** - Optimized for metrics with CORS support
- **📋 Loki Storage** - Optimized for log chunks with aggressive lifecycle
- **🔍 Tempo Storage** - Optimized for trace data with configurable retention
- **💰 Cost Optimization** - Intelligent lifecycle transitions to cheaper storage classes
- **🔒 Security First** - Public access blocked, versioning, access logging
- **📈 Monitoring** - SNS notifications and CloudWatch integration
- **⚡ Performance** - Transfer acceleration and intelligent tiering support

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Observability │    │   S3 Buckets     │    │  Storage Classes│
│   Services      │────│   + KMS Keys     │────│                 │
│                 │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
│                      │                      │
├─ Mimir (metrics)    ├─ mimir-bucket        ├─ STANDARD → IA → GLACIER
├─ Loki (logs)        ├─ loki-bucket         ├─ STANDARD → IA → GLACIER
└─ Tempo (traces)     └─ tempo-bucket        └─ STANDARD → IA → GLACIER
```

## Quick Start

```hcl
module "observability_s3" {
  source = "./modules/s3-kms"

  environment  = "prod"
  project_name = "observability"

  # Create buckets for your stack
  create_mimir_bucket = true
  create_loki_bucket  = true
  create_tempo_bucket = false

  # KMS encryption
  create_kms_key      = true
  enable_key_rotation = true

  # Lifecycle management
  enable_lifecycle_management = true
  logs_retention_days         = 365
  traces_retention_days       = 90
}
```

## Bucket Purposes

### Mimir Bucket

- **Purpose**: Long-term metrics storage and querying
- **Access Pattern**: Frequent reads, batch writes
- **Optimization**: CORS enabled, intelligent tiering
- **Retention**: Configurable with lifecycle policies

### Loki Bucket

- **Purpose**: Log chunks and index data storage
- **Access Pattern**: Write-heavy, occasional reads
- **Optimization**: Aggressive lifecycle transitions
- **Retention**: Configurable auto-deletion

### Tempo Bucket

- **Purpose**: Distributed trace data storage
- **Access Pattern**: Recent traces accessed frequently
- **Optimization**: Medium lifecycle transitions
- **Retention**: Configurable based on compliance needs

## Security Features

- ✅ **Customer-Managed KMS** - Full control over encryption keys
- ✅ **Public Access Blocked** - All public access disabled by default
- ✅ **Versioning Enabled** - Protection against accidental deletion
- ✅ **Access Logging** - Comprehensive audit trail
- ✅ **Bucket Policies** - Fine-grained access control
- ✅ **SSL/TLS Only** - Enforce encrypted connections

## Cost Optimization

### Lifecycle Transitions

```
STANDARD (0-30 days) → STANDARD_IA (30-90 days) → GLACIER (90-365 days) → DEEP_ARCHIVE (365+ days)
```

### Intelligent Features

- **Intelligent Tiering** - Automatic cost optimization
- **Transfer Acceleration** - Faster uploads for global teams
- **Multipart Upload Cleanup** - Remove incomplete uploads
- **Version Expiration** - Remove old object versions

## Integration

Works seamlessly with our other observability modules:

```hcl
# Complete observability stack
module "dynamodb" { source = "./modules/dynamodb" }
module "s3_storage" { source = "./modules/s3-kms" }
module "iam_roles" {
  source = "./modules/iam"
  mimir_s3_bucket_arn = module.s3_storage.mimir_bucket_arn
  loki_s3_bucket_arn  = module.s3_storage.loki_bucket_arn
}
```

## Usage Examples

### Basic Setup - Mimir Only

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

### Full Observability Stack

```hcl
module "observability_s3" {
  source = "./modules/s3-kms"

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
  enable_versioning     = true
  enable_access_logging = true

  # Lifecycle management for cost optimization
  enable_lifecycle_management = true
  logs_retention_days         = 365  # 1 year for logs
  traces_retention_days       = 90   # 3 months for traces

  # CORS for Mimir web interface
  enable_cors = true
  cors_allowed_origins = [
    "https://mimir.company.com",
    "https://grafana.company.com"
  ]

  tags = {
    Environment   = "prod"
    Team          = "platform"
    CostCenter    = "engineering"
    Compliance    = "SOC2"
  }
}
```

### Development Environment

```hcl
module "observability_s3" {
  source = "./modules/s3-kms"

  environment  = "dev"
  project_name = "observability"

  # Minimal setup for development
  create_mimir_bucket = true
  create_loki_bucket  = false
  create_tempo_bucket = false

  # Cost optimization for dev
  create_kms_key = false  # Use default encryption
  enable_versioning           = false  # Reduce costs
  enable_lifecycle_management = true

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

## Application Integration

### Mimir Configuration

```yaml
# mimir-values.yaml
blocks_storage:
  backend: s3
  s3:
    bucket_name: "${module.observability_s3.mimir_bucket_name}"
    region: "${module.observability_s3.mimir_bucket_region}"
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

## Lifecycle Management

### Automatic Transitions

```
Day 0-30:   STANDARD (immediate access)
Day 30-90:  STANDARD_IA (less frequent access)
Day 90-365: GLACIER (archival)
Day 365+:   DEEP_ARCHIVE (long-term archival)
```

### Cost Optimization Features

- **Intelligent Tiering**: Automatic cost optimization based on access patterns
- **Transfer Acceleration**: Faster uploads for global teams
- **Multipart Upload Cleanup**: Remove incomplete uploads automatically
- **Version Expiration**: Clean up old object versions

## Security Best Practices

### Encryption

- ✅ **Customer-managed KMS keys** with automatic rotation
- ✅ **Bucket-level encryption** for all objects
- ✅ **Versioning** enabled for data protection

### Access Control

- ✅ **Public access blocked** by default
- ✅ **IAM policies** integrated with service roles
- ✅ **VPC endpoints** support through custom policies
- ✅ **SSL/TLS only** connections enforced

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

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | >= 1.0  |
| aws       | >= 5.0  |

## Dependencies

- **EKS cluster** for service account integration
- **VPC endpoints** (optional) for private S3 access

## Outputs

| Name                | Description                      |
| ------------------- | -------------------------------- |
| `mimir_bucket_arn`  | ARN of Mimir S3 bucket           |
| `mimir_bucket_name` | Name of Mimir S3 bucket          |
| `loki_bucket_arn`   | ARN of Loki S3 bucket            |
| `loki_bucket_name`  | Name of Loki S3 bucket           |
| `tempo_bucket_arn`  | ARN of Tempo S3 bucket           |
| `tempo_bucket_name` | Name of Tempo S3 bucket          |
| `kms_key_arn`       | ARN of KMS encryption key        |
| `kms_key_id`        | ID of KMS encryption key         |
| `buckets_summary`   | Complete summary for integration |

## Cost Estimation

### Monthly Costs (Approximate)

- **Development**: $10-50/month (minimal data, aggressive lifecycle)
- **Production**: $100-500/month (depends on data volume and retention)
- **Enterprise**: $500-2000/month (high volume, compliance requirements)

### Cost Factors

- **Storage Volume**: Primary cost driver based on data retention
- **Request Patterns**: GET/PUT operations and frequency
- **Data Transfer**: Cross-region and internet egress costs
- **Storage Classes**: Lifecycle optimization impact on costs

### Cost Optimization Tips

1. **Use Lifecycle Policies**: Automatic transitions to cheaper storage classes
2. **Enable Intelligent Tiering**: Optimize costs based on access patterns
3. **Configure Proper Retention**: Don't store data longer than necessary
4. **Monitor Usage**: Regular review of storage analytics and costs
