# DynamoDB Module

This Terraform module creates DynamoDB tables for observability infrastructure, specifically designed for metrics and logs indexing. It uses the [CloudPosse DynamoDB module](https://github.com/cloudposse/terraform-aws-dynamodb) as a remote module for best practices.

## Features

- **Flexible Table Creation**: Choose which tables to create (Mimir, Loki, or both)
- **CloudPosse Integration**: Uses proven CloudPosse DynamoDB module
- **Production Ready**: Encryption, backup, autoscaling support
- **Cost Optimized**: PAY_PER_REQUEST billing by default
- **Monitoring Ready**: Proper tagging and naming conventions

## Usage

### Basic Usage

```hcl
module "dynamodb" {
  source = "./modules/dynamodb"

  environment  = "dev"
  project_name = "observability"

  # Encryption
  kms_key_arn                    = module.kms.key_arn
  server_side_encryption_enabled = true

  # Backup
  point_in_time_recovery_enabled = true

  tags = {
    Environment = "dev"
    Project     = "observability"
  }
}
```

### Advanced Usage with Provisioned Billing

```hcl
module "dynamodb" {
  source = "./modules/dynamodb"

  environment  = "prod"
  project_name = "observability"

  # Billing configuration
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20

  # Autoscaling
  autoscaling_enabled = true
  autoscaling_read = {
    min_capacity = 5
    max_capacity = 1000
  }
  autoscaling_write = {
    min_capacity = 5
    max_capacity = 1000
  }

  # Additional GSI
  global_secondary_indexes = [
    {
      name            = "custom-index"
      hash_key        = "custom_key"
      projection_type = "KEYS_ONLY"
      read_capacity   = 5
      write_capacity  = 5
    }
  ]

  # Encryption
  kms_key_arn                    = module.kms.key_arn
  server_side_encryption_enabled = true

  tags = {
    Environment = "prod"
    Project     = "observability"
  }
}
```

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | >= 1.0  |
| aws       | ~> 5.0  |

## Providers

| Name | Version |
| ---- | ------- |
| aws  | ~> 5.0  |

## Modules

| Name              | Source                  | Version   |
| ----------------- | ----------------------- | --------- |
| mimir_index_table | cloudposse/dynamodb/aws | ~> 0.35.0 |
| loki_index_table  | cloudposse/dynamodb/aws | ~> 0.35.0 |

## Resources

No additional resources created directly by this module.

## Inputs

| Name                           | Description                                                       | Type           | Default             | Required |
| ------------------------------ | ----------------------------------------------------------------- | -------------- | ------------------- | :------: |
| environment                    | Environment name (dev, staging, prod)                             | `string`       | n/a                 |   yes    |
| project_name                   | Name of the project                                               | `string`       | `"observability"`   |    no    |
| mimir_table_name               | Name for the Mimir index table                                    | `string`       | `null`              |    no    |
| billing_mode                   | DynamoDB billing mode (PAY_PER_REQUEST or PROVISIONED)            | `string`       | `"PAY_PER_REQUEST"` |    no    |
| read_capacity                  | Read capacity units (only used when billing_mode is PROVISIONED)  | `number`       | `5`                 |    no    |
| write_capacity                 | Write capacity units (only used when billing_mode is PROVISIONED) | `number`       | `5`                 |    no    |
| kms_key_arn                    | ARN of KMS key for DynamoDB encryption                            | `string`       | `null`              |    no    |
| server_side_encryption_enabled | Enable server-side encryption for DynamoDB                        | `bool`         | `true`              |    no    |
| point_in_time_recovery_enabled | Enable point-in-time recovery for DynamoDB                        | `bool`         | `true`              |    no    |
| autoscaling_enabled            | Enable autoscaling for DynamoDB table                             | `bool`         | `false`             |    no    |
| global_secondary_indexes       | List of global secondary indexes                                  | `list(object)` | `[]`                |    no    |
| tags                           | Additional tags for DynamoDB tables                               | `map(string)`  | `{}`                |    no    |

## Outputs

| Name                           | Description                                 |
| ------------------------------ | ------------------------------------------- |
| mimir_table_name               | Name of the Mimir DynamoDB table            |
| mimir_table_id                 | ID of the Mimir DynamoDB table              |
| mimir_table_arn                | ARN of the Mimir DynamoDB table             |
| mimir_table_stream_arn         | ARN of the Mimir DynamoDB table stream      |
| mimir_global_secondary_indexes | Global Secondary Indexes of the Mimir table |
| loki_table_name                | Name of the Loki DynamoDB table             |
| loki_table_arn                 | ARN of the Loki DynamoDB table              |

## Table Schema Overview

### Mimir Index Table

**Purpose**: Store metrics metadata and index information for fast retrieval

**Primary Key**:

- Hash Key: `metric_name` (S) - The name of the metric (e.g., "cpu.usage")
- Range Key: `timestamp` (S) - ISO timestamp for time-based queries

**Attributes**:

- `tenant_id` (S) - Multi-tenant isolation
- `labels_hash` (S) - Hash of metric labels for efficient lookups

**Global Secondary Indexes**:

1. **tenant-timestamp-index**: Query by tenant and time range

   - Hash: `tenant_id`, Range: `timestamp`
   - Use case: Get all metrics for a specific tenant in a time range

2. **labels-index**: Query by label combinations
   - Hash: `labels_hash`, Range: `timestamp`
   - Use case: Find metrics with specific label combinations

### Loki Index Table (Optional)

**Purpose**: Store log stream metadata and chunk information

**Primary Key**:

- Hash Key: `stream_id` (S) - Unique identifier for log stream
- Range Key: `chunk_id` (S) - Chunk identifier with timestamp

**Attributes**:

- `tenant_id` (S) - Multi-tenant isolation
- `log_level` (S) - Log level (INFO, WARN, ERROR, etc.)
- `service_name` (S) - Service that generated the logs

**Global Secondary Indexes**:

1. **tenant-service-index**: Query by tenant and service

   - Hash: `tenant_id`, Range: `service_name`
   - Use case: Get all logs for a specific service in a tenant

2. **log-level-index**: Query by log level
   - Hash: `log_level`, Range: `chunk_id`
   - Use case: Find all ERROR/WARN logs across services

## Usage Examples

### Development Environment

```hcl
module "monitoring_dynamodb" {
  source = "./modules/dynamodb"

  # Development configuration
  environment  = "dev"
  project_name = "observability"

  # Only Mimir for development (cost optimization)
  create_mimir_table = true
  create_loki_table  = false

  # Cost-effective on-demand billing
  billing_mode = "PAY_PER_REQUEST"

  # Minimal security for development
  server_side_encryption_enabled = true
  point_in_time_recovery_enabled = false

  tags = {
    Environment = "dev"
    Team        = "platform"
    Purpose     = "development"
  }
}
```

### Full Production Stack

```hcl
module "monitoring_dynamodb" {
  source = "./modules/dynamodb"

  environment  = "prod"
  project_name = "observability"

  # Create both tables for comprehensive monitoring
  create_mimir_table = true
  create_loki_table  = true

  # High-throughput provisioned billing with autoscaling
  billing_mode = "PROVISIONED"
  read_capacity  = 50
  write_capacity = 50

  # Autoscaling configuration
  autoscaling_enabled = true
  autoscaling_read = {
    min_capacity = 25
    max_capacity = 500
  }
  autoscaling_write = {
    min_capacity = 25
    max_capacity = 500
  }

  # Security and compliance
  server_side_encryption_enabled = true
  kms_key_arn                    = module.kms.key_arn
  point_in_time_recovery_enabled = true

  tags = {
    Environment   = "prod"
    Team          = "platform"
    Compliance    = "SOC2"
    BackupPolicy  = "7-days"
  }
}
```

## Integration with Observability Stack

### Mimir Configuration

```yaml
# mimir.yaml
blocks_storage:
  backend: s3
  s3:
    bucket_name: observability-mimir-bucket

index_queries:
  backend: dynamodb
  dynamodb:
    original_table_name: observability-mimir-index-prod
```

### Using Outputs in Helm Charts

```hcl
# Configure Mimir with DynamoDB table
resource "helm_release" "mimir" {
  name       = "mimir"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "mimir-distributed"

  set {
    name  = "mimir.storage.dynamodb.table_name"
    value = module.monitoring_dynamodb.mimir_table_name
  }

  set {
    name  = "mimir.storage.dynamodb.region"
    value = module.monitoring_dynamodb.mimir_table_endpoint.region
  }
}
```

## Cost Optimization Tips

### 1. Billing Mode Selection

- **PAY_PER_REQUEST**: Best for unpredictable/variable workloads
- **PROVISIONED**: Better for consistent high-throughput (use with autoscaling)

### 2. Table Creation Flags

- Only create tables you actually use
- `create_loki_table = false` for metrics-only deployments

### 3. Environment-Specific Configuration

- Development: PAY_PER_REQUEST, no PITR, minimal GSIs
- Production: PROVISIONED + autoscaling, full security, comprehensive GSIs

## Why CloudPosse Module?

This module uses the CloudPosse DynamoDB Terraform module for several reasons:

1. **Battle-tested**: Used by thousands of projects
2. **CloudPosse Standards**: Consistent naming and tagging
3. **Comprehensive**: All DynamoDB features supported
4. **Active Maintenance**: Regular updates and bug fixes
5. **Documentation**: Excellent examples and documentation

### CloudPosse Module Capabilities

- **Hash Key & Range Key**: Flexible key configuration with type specification
- **Billing Modes**: PROVISIONED or PAY_PER_REQUEST
- **Autoscaling**: Built-in autoscaling with configurable targets
- **Security**: Server-side encryption with optional KMS key
- **Backup**: Point-in-time recovery support
- **Indexes**: Full GSI and LSI support
- **Streams**: DynamoDB streams for change data capture
