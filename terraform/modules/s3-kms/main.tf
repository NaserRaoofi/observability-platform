# S3 Buckets with KMS Encryption for Observability Stack
# This module creates S3 buckets for Mimir, Loki, and Tempo with proper encryption and lifecycle policies

# Local values for consistent naming and configuration
locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = var.project_name
      Component   = "observability-storage"
      ManagedBy   = "terraform"
    }
  )

  # Bucket naming with environment and project
  bucket_prefix = "${var.project_name}-${var.environment}"

  # Common lifecycle configuration for cost optimization
  lifecycle_configuration = {
    rule = [
      {
        id     = "observability_lifecycle"
        status = "Enabled"

        # Transition to IA after 30 days
        transition = [
          {
            days          = 30
            storage_class = "STANDARD_IA"
          },
          {
            days          = 90
            storage_class = "GLACIER"
          },
          {
            days          = 365
            storage_class = "DEEP_ARCHIVE"
          }
        ]

        # Delete old versions after retention period
        noncurrent_version_transition = [
          {
            noncurrent_days = 30
            storage_class   = "STANDARD_IA"
          },
          {
            noncurrent_days = 90
            storage_class   = "GLACIER"
          }
        ]

        noncurrent_version_expiration = {
          noncurrent_days = var.noncurrent_version_retention_days
        }

        # Expire multipart uploads after 7 days
        abort_incomplete_multipart_upload = {
          days_after_initiation = 7
        }
      }
    ]
  }
}

# ===============================================================================
# KMS KEY FOR S3 ENCRYPTION
# ===============================================================================

# KMS key for S3 bucket encryption
resource "aws_kms_key" "s3_encryption" {
  count = var.create_kms_key ? 1 : 0

  description             = "KMS key for ${var.project_name} observability S3 bucket encryption"
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation

  tags = merge(local.common_tags, {
    Name = "${local.bucket_prefix}-s3-encryption"
  })
}

# KMS key alias for easier identification
resource "aws_kms_alias" "s3_encryption" {
  count = var.create_kms_key ? 1 : 0

  name          = "alias/${local.bucket_prefix}-s3-encryption"
  target_key_id = aws_kms_key.s3_encryption[0].key_id
}

# ===============================================================================
# MIMIR S3 BUCKET - Metrics Storage
# ===============================================================================

module "mimir_bucket" {
  source = "github.com/NaserRaoofi/terraform-aws-modules//modules/s3-bucket?ref=main"

  count = var.create_mimir_bucket ? 1 : 0

  bucket = "${local.bucket_prefix}-mimir-metrics"

  # Security configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Versioning for data protection
  versioning = {
    enabled = var.enable_versioning
  }

  # Server-side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = var.create_kms_key ? aws_kms_key.s3_encryption[0].arn : var.existing_kms_key_arn
        sse_algorithm     = "aws:kms"
      }
      bucket_key_enabled = true
    }
  }

  # Lifecycle management for cost optimization
  lifecycle_rule = var.enable_lifecycle_management ? [
    {
      id     = "observability_lifecycle"
      status = "Enabled"

      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        },
        {
          days          = 365
          storage_class = "DEEP_ARCHIVE"
        }
      ]

      noncurrent_version_transition = [
        {
          noncurrent_days = 30
          storage_class   = "STANDARD_IA"
        },
        {
          noncurrent_days = 90
          storage_class   = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        noncurrent_days = 365
      }

      expiration = {
        days = 2555 # ~7 years default retention
      }
    }
  ] : []

  # CORS configuration for Mimir web interface
  cors_rule = var.enable_cors ? [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
      allowed_origins = var.cors_allowed_origins
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
    }
  ] : []

  # Logging configuration
  logging = var.enable_access_logging ? {
    target_bucket = var.access_log_bucket_name != null ? var.access_log_bucket_name : "${local.bucket_prefix}-access-logs"
    target_prefix = "mimir-metrics/"
  } : {}

  tags = merge(local.common_tags, {
    Name      = "${local.bucket_prefix}-mimir-metrics"
    Component = "mimir-storage"
    Purpose   = "metrics-storage"
    DataType  = "metrics"
  })
}

# ===============================================================================
# LOKI S3 BUCKET - Logs Storage
# ===============================================================================

module "loki_bucket" {
  source = "github.com/NaserRaoofi/terraform-aws-modules//modules/s3-bucket?ref=main"

  count = var.create_loki_bucket ? 1 : 0

  bucket = "${local.bucket_prefix}-loki-logs"

  # Security configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Versioning for data protection
  versioning = {
    enabled = var.enable_versioning
  }

  # Server-side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = var.create_kms_key ? aws_kms_key.s3_encryption[0].arn : var.existing_kms_key_arn
        sse_algorithm     = "aws:kms"
      }
      bucket_key_enabled = true
    }
  }

  # Lifecycle management for cost optimization (shorter retention for logs)
  lifecycle_rule = var.enable_lifecycle_management ? [
    {
      id     = "loki_logs_lifecycle"
      status = "Enabled"

      # Faster transition for logs (typically accessed less frequently)
      transition = [
        {
          days          = 7
          storage_class = "STANDARD_IA"
        },
        {
          days          = 30
          storage_class = "GLACIER"
        },
        {
          days          = 90
          storage_class = "DEEP_ARCHIVE"
        }
      ]

      # Auto-delete logs after retention period
      expiration = var.logs_retention_days > 0 ? {
        days = var.logs_retention_days
      } : null

      noncurrent_version_expiration = {
        noncurrent_days = 30
      }

      abort_incomplete_multipart_upload = {
        days_after_initiation = 7
      }
    }
  ] : []

  tags = merge(local.common_tags, {
    Name      = "${local.bucket_prefix}-loki-logs"
    Component = "loki-storage"
    Purpose   = "logs-storage"
    DataType  = "logs"
  })
}

# ===============================================================================
# TEMPO S3 BUCKET - Traces Storage
# ===============================================================================

module "tempo_bucket" {
  source = "github.com/NaserRaoofi/terraform-aws-modules//modules/s3-bucket?ref=main"

  count = var.create_tempo_bucket ? 1 : 0

  bucket = "${local.bucket_prefix}-tempo-traces"

  # Security configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Versioning for data protection
  versioning = {
    enabled = var.enable_versioning
  }

  # Server-side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = var.create_kms_key ? aws_kms_key.s3_encryption[0].arn : var.existing_kms_key_arn
        sse_algorithm     = "aws:kms"
      }
      bucket_key_enabled = true
    }
  }

  # Lifecycle management for traces (medium retention)
  lifecycle_rule = var.enable_lifecycle_management ? [
    {
      id     = "tempo_traces_lifecycle"
      status = "Enabled"

      # Traces are accessed frequently initially, then rarely
      transition = [
        {
          days          = 14
          storage_class = "STANDARD_IA"
        },
        {
          days          = 60
          storage_class = "GLACIER"
        }
      ]

      # Auto-delete traces after retention period
      expiration = var.traces_retention_days > 0 ? {
        days = var.traces_retention_days
      } : null

      noncurrent_version_expiration = {
        noncurrent_days = 30
      }

      abort_incomplete_multipart_upload = {
        days_after_initiation = 7
      }
    }
  ] : []

  # Logging configuration
  logging = var.enable_access_logging ? {
    target_bucket = var.access_log_bucket_name != null ? var.access_log_bucket_name : "${local.bucket_prefix}-access-logs"
    target_prefix = "tempo-traces/"
  } : {}

  tags = merge(local.common_tags, {
    Name      = "${local.bucket_prefix}-tempo-traces"
    Component = "tempo-storage"
    Purpose   = "traces-storage"
    DataType  = "traces"
  })
}

# ===============================================================================
# ACCESS LOGS BUCKET (Optional)
# ===============================================================================

module "access_logs_bucket" {
  source = "github.com/NaserRaoofi/terraform-aws-modules//modules/s3-bucket?ref=main"

  count = var.enable_access_logging && var.access_log_bucket_name == null ? 1 : 0

  bucket = "${local.bucket_prefix}-access-logs"

  # Security configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # No versioning needed for access logs
  versioning = {
    enabled = false
  }

  # Server-side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = var.create_kms_key ? aws_kms_key.s3_encryption[0].arn : var.existing_kms_key_arn
        sse_algorithm     = "aws:kms"
      }
      bucket_key_enabled = true
    }
  }

  # Lifecycle management for access logs (short retention)
  lifecycle_rule = [
    {
      id     = "access_logs_lifecycle"
      status = "Enabled"

      # Delete access logs after 30 days
      expiration = {
        days = var.access_logs_retention_days
      }

      abort_incomplete_multipart_upload = {
        days_after_initiation = 1
      }
    }
  ]

  tags = merge(local.common_tags, {
    Name      = "${local.bucket_prefix}-access-logs"
    Component = "access-logs"
    Purpose   = "access-logging"
  })
}
