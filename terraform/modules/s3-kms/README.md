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

## Usage

See [USAGE_EXAMPLES.md](./USAGE_EXAMPLES.md) for detailed examples and configurations.

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | >= 1.0  |
| aws       | >= 5.0  |

## Dependencies

- **terraform-aws-s3-bucket** module (cloned at project root)

## Outputs

| Name               | Description                      |
| ------------------ | -------------------------------- |
| `mimir_bucket_arn` | ARN of Mimir S3 bucket           |
| `loki_bucket_arn`  | ARN of Loki S3 bucket            |
| `tempo_bucket_arn` | ARN of Tempo S3 bucket           |
| `kms_key_arn`      | ARN of KMS encryption key        |
| `buckets_summary`  | Complete summary for integration |

## Cost Estimation

### Monthly Costs (approximate)

- **Development**: $10-50/month (minimal data, aggressive lifecycle)
- **Production**: $100-500/month (depends on data volume and retention)
- **Enterprise**: $500-2000/month (high volume, compliance requirements)

### Cost Factors

- **Storage volume** - Primary cost driver
- **Request patterns** - GET/PUT operations
- **Data transfer** - Cross-region, internet egress
- **Storage classes** - Lifecycle optimization impact
