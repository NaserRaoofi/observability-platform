# DynamoDB Module Usage Examples for Monitoring Stack

## Basic Usage - Mimir Only (Metrics)

```hcl
module "monitoring_dynamodb" {
  source = "./modules/dynamodb"

  # Environment configuration
  environment  = "prod"
  project_name = "observability"

  # Table creation flags
  create_mimir_table = true
  create_loki_table  = false

  # Billing mode (cost-effective for variable workloads)
  billing_mode = "PAY_PER_REQUEST"

  # Security
  server_side_encryption_enabled = true
  kms_key_arn                    = module.kms.key_arn
  point_in_time_recovery_enabled = true

  # Tags
  tags = {
    Environment = "prod"
    Team        = "platform"
    CostCenter  = "engineering"
  }
}
```

## Full Monitoring Stack (Metrics + Logs)

```hcl
module "monitoring_dynamodb" {
  source = "./modules/dynamodb"

  # Environment configuration
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

  # Resource tagging
  tags = {
    Environment   = "prod"
    Team          = "platform"
    CostCenter    = "engineering"
    Compliance    = "SOC2"
    BackupPolicy  = "7-days"
  }
}
```

## Development Environment

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

  # Development tags
  tags = {
    Environment = "dev"
    Team        = "platform"
    Purpose     = "development"
    AutoDelete  = "true"
  }
}
```

## Outputs Usage

```hcl
# Use the outputs to configure Mimir
resource "helm_release" "mimir" {
  # ... helm configuration ...

  set {
    name  = "mimir.storage.dynamodb.table_name"
    value = module.monitoring_dynamodb.mimir_table_name
  }

  set {
    name  = "mimir.storage.dynamodb.region"
    value = module.monitoring_dynamodb.mimir_table_endpoint.region
  }
}

# Use the outputs to configure Loki (if enabled)
resource "helm_release" "loki" {
  count = var.enable_loki ? 1 : 0

  # ... helm configuration ...

  set {
    name  = "loki.storage.dynamodb.table_name"
    value = module.monitoring_dynamodb.loki_table_name
  }

  set {
    name  = "loki.storage.dynamodb.region"
    value = module.monitoring_dynamodb.loki_table_endpoint.region
  }
}
```

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

### 4. Monitoring and Alerting

```hcl
# CloudWatch alarms for cost monitoring
resource "aws_cloudwatch_metric_alarm" "dynamodb_consumed_read_capacity" {
  alarm_name          = "dynamodb-mimir-high-read-capacity"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ConsumedReadCapacityUnits"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1000"
  alarm_description   = "This metric monitors DynamoDB read capacity"

  dimensions = {
    TableName = module.monitoring_dynamodb.mimir_table_name
  }
}
```
