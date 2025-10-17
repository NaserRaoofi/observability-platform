# Local values for consistent naming and tags
locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = var.project_name
      Component   = "observability-dynamodb"
      ManagedBy   = "terraform"
      Purpose     = "observability-storage"
    }
  )
}

# DynamoDB tables for observability components
# This module creates the necessary DynamoDB tables for the observability stack

# Mimir Index Table - Metrics storage for long-term retention
module "mimir_index_table" {
  source = "../../../terraform-aws-dynamodb"

  # Only create if explicitly enabled
  count = var.create_mimir_table ? 1 : 0

  # CloudPosse naming convention
  namespace = var.project_name
  stage     = var.environment
  name      = "mimir-index"

  # Table configuration optimized for Mimir metrics indexing
  hash_key  = "metric_name"
  range_key = "timestamp"
  dynamodb_attributes = [
    {
      name = "metric_name"
      type = "S"  # String: metric name (e.g., "cpu.usage", "memory.utilization")
    },
    {
      name = "timestamp"
      type = "S"  # String: ISO timestamp for time-based queries
    },
    {
      name = "tenant_id"
      type = "S"  # String: for multi-tenant metrics isolation
    },
    {
      name = "labels_hash"
      type = "S"  # String: hash of metric labels for efficient lookups
    }
  ]

  # Billing configuration
  billing_mode = var.billing_mode

  # Capacity settings for PROVISIONED mode
  autoscale_min_read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  autoscale_min_write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null
  autoscale_max_read_capacity  = var.billing_mode == "PROVISIONED" ? var.autoscaling_read.max_capacity : null
  autoscale_max_write_capacity = var.billing_mode == "PROVISIONED" ? var.autoscaling_write.max_capacity : null

  # Global Secondary Indexes for efficient metrics querying
  global_secondary_index_map = [
    {
      name               = "tenant-timestamp-index"
      hash_key           = "tenant_id"
      range_key          = "timestamp"
      projection_type    = "ALL"
      read_capacity      = var.billing_mode == "PROVISIONED" ? var.read_capacity : 5
      write_capacity     = var.billing_mode == "PROVISIONED" ? var.write_capacity : 5
      non_key_attributes = []
    },
    {
      name               = "labels-index"
      hash_key           = "labels_hash"
      range_key          = "timestamp"
      projection_type    = "KEYS_ONLY"
      read_capacity      = var.billing_mode == "PROVISIONED" ? var.read_capacity : 5
      write_capacity     = var.billing_mode == "PROVISIONED" ? var.write_capacity : 5
      non_key_attributes = []
    }
  ]

  # Security and backup
  enable_encryption                  = var.server_side_encryption_enabled
  server_side_encryption_kms_key_arn = var.kms_key_arn
  enable_point_in_time_recovery     = var.point_in_time_recovery_enabled

  # Autoscaling
  enable_autoscaler      = var.autoscaling_enabled && var.billing_mode == "PROVISIONED"
  autoscale_read_target  = 70
  autoscale_write_target = 70

  # Tags
  tags = merge(local.common_tags, {
    Component = "mimir-storage"
    Purpose   = "metrics-index"
  })
}

# Optional Loki Index Table - Logs indexing for faster queries
module "loki_index_table" {
  source = "../../../terraform-aws-dynamodb"

  # Only create if explicitly enabled via variable
  count = var.create_loki_table ? 1 : 0

  # CloudPosse naming convention
  namespace = var.project_name
  stage     = var.environment
  name      = "loki-index"

  # Table configuration optimized for Loki logs indexing
  hash_key  = "stream_id"
  range_key = "chunk_id"
  dynamodb_attributes = [
    {
      name = "stream_id"
      type = "S"  # String: unique stream identifier
    },
    {
      name = "chunk_id"
      type = "S"  # String: chunk identifier with timestamp
    },
    {
      name = "tenant_id"
      type = "S"  # String: for multi-tenant log isolation
    },
    {
      name = "log_level"
      type = "S"  # String: log level (INFO, WARN, ERROR, etc.)
    },
    {
      name = "service_name"
      type = "S"  # String: service that generated the logs
    }
  ]  # Billing configuration
  billing_mode = var.billing_mode

  # Capacity settings
  autoscale_min_read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  autoscale_min_write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null
  autoscale_max_read_capacity  = var.billing_mode == "PROVISIONED" ? var.autoscaling_read.max_capacity : null
  autoscale_max_write_capacity = var.billing_mode == "PROVISIONED" ? var.autoscaling_write.max_capacity : null

  # Security and backup
  enable_encryption                  = var.server_side_encryption_enabled
  server_side_encryption_kms_key_arn = var.kms_key_arn
  enable_point_in_time_recovery     = var.point_in_time_recovery_enabled

  # Global Secondary Indexes for efficient log querying
  global_secondary_index_map = [
    {
      name               = "tenant-service-index"
      hash_key           = "tenant_id"
      range_key          = "service_name"
      projection_type    = "ALL"
      read_capacity      = var.billing_mode == "PROVISIONED" ? var.read_capacity : 5
      write_capacity     = var.billing_mode == "PROVISIONED" ? var.write_capacity : 5
      non_key_attributes = []
    },
    {
      name               = "log-level-index"
      hash_key           = "log_level"
      range_key          = "chunk_id"
      projection_type    = "INCLUDE"
      read_capacity      = var.billing_mode == "PROVISIONED" ? var.read_capacity : 5
      write_capacity     = var.billing_mode == "PROVISIONED" ? var.write_capacity : 5
      non_key_attributes = ["stream_id", "service_name"]
    }
  ]

  # Autoscaling
  enable_autoscaler      = var.autoscaling_enabled && var.billing_mode == "PROVISIONED"
  autoscale_read_target  = 70
  autoscale_write_target = 70

  # Tags
  tags = merge(local.common_tags, {
    Component = "loki-storage"
    Purpose   = "logs-index"
  })
}
