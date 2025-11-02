# Development Environment Outputs
# Comprehensive outputs for observability stack integration

# ==========================================
# DynamoDB Module Outputs
# ==========================================

output "dynamodb_outputs" {
  description = "DynamoDB module outputs for development"
  value = {
    mimir_table_name = module.observability_dynamodb.mimir_table_name
    mimir_table_arn  = module.observability_dynamodb.mimir_table_arn
    loki_table_name  = module.observability_dynamodb.loki_table_name
    loki_table_arn   = module.observability_dynamodb.loki_table_arn
  }
}

# Individual DynamoDB outputs for convenience
output "mimir_table_name" {
  description = "Name of the Mimir DynamoDB table"
  value       = module.observability_dynamodb.mimir_table_name
}

output "mimir_table_arn" {
  description = "ARN of the Mimir DynamoDB table"
  value       = module.observability_dynamodb.mimir_table_arn
}

output "loki_table_name" {
  description = "Name of the Loki DynamoDB table"
  value       = module.observability_dynamodb.loki_table_name
}

output "loki_table_arn" {
  description = "ARN of the Loki DynamoDB table"
  value       = module.observability_dynamodb.loki_table_arn
}

# ==========================================
# S3-KMS Module Outputs
# ==========================================

output "s3_outputs" {
  description = "S3 module outputs for development"
  value = {
    mimir_bucket_name = module.observability_s3.mimir_bucket_name
    mimir_bucket_arn  = module.observability_s3.mimir_bucket_arn
    loki_bucket_name  = module.observability_s3.loki_bucket_name
    loki_bucket_arn   = module.observability_s3.loki_bucket_arn
    tempo_bucket_name = module.observability_s3.tempo_bucket_name
    tempo_bucket_arn  = module.observability_s3.tempo_bucket_arn
    kms_key_arn       = module.observability_s3.kms_key_arn
    kms_key_id        = module.observability_s3.kms_key_id
  }
}

# Individual S3 outputs for convenience
output "mimir_bucket_name" {
  description = "Name of the Mimir S3 bucket"
  value       = module.observability_s3.mimir_bucket_name
}

output "mimir_bucket_arn" {
  description = "ARN of the Mimir S3 bucket"
  value       = module.observability_s3.mimir_bucket_arn
}

output "loki_bucket_name" {
  description = "Name of the Loki S3 bucket"
  value       = module.observability_s3.loki_bucket_name
}

output "loki_bucket_arn" {
  description = "ARN of the Loki S3 bucket"
  value       = module.observability_s3.loki_bucket_arn
}

output "tempo_bucket_name" {
  description = "Name of the Tempo S3 bucket"
  value       = module.observability_s3.tempo_bucket_name
}

output "tempo_bucket_arn" {
  description = "ARN of the Tempo S3 bucket"
  value       = module.observability_s3.tempo_bucket_arn
}

output "kms_key_arn" {
  description = "ARN of the KMS encryption key"
  value       = module.observability_s3.kms_key_arn
}

output "kms_key_id" {
  description = "ID of the KMS encryption key"
  value       = module.observability_s3.kms_key_id
}

# ==========================================
# IAM Module Outputs
# ==========================================

output "iam_outputs" {
  description = "IAM module outputs for development"
  value = {
    mimir_role_arn   = module.observability_iam.mimir_role_arn
    loki_role_arn    = module.observability_iam.loki_role_arn
    grafana_role_arn = module.observability_iam.grafana_role_arn
    tempo_role_arn   = module.observability_iam.tempo_role_arn
  }
}

# Individual IAM outputs for convenience
output "mimir_role_arn" {
  description = "ARN of the Mimir IAM role"
  value       = module.observability_iam.mimir_role_arn
}

output "loki_role_arn" {
  description = "ARN of the Loki IAM role"
  value       = module.observability_iam.loki_role_arn
}

output "grafana_role_arn" {
  description = "ARN of the Grafana IAM role"
  value       = module.observability_iam.grafana_role_arn
}

output "tempo_role_arn" {
  description = "ARN of the Tempo IAM role"
  value       = module.observability_iam.tempo_role_arn
}

# ==========================================
# Development Stack Summary
# ==========================================

output "dev_observability_summary" {
  description = "Development observability stack configuration summary"
  value = {
    environment = var.environment

    # Enabled services
    enabled_services = {
      mimir   = var.create_mimir_table
      loki    = var.create_loki_table
      tempo   = var.create_tempo_bucket
      grafana = var.create_grafana_role
    }

    # Storage resources
    storage = {
      mimir_table  = var.create_mimir_table ? module.observability_dynamodb.mimir_table_name : "disabled"
      mimir_bucket = var.create_mimir_bucket ? module.observability_s3.mimir_bucket_name : "disabled"
      loki_table   = var.create_loki_table ? module.observability_dynamodb.loki_table_name : "disabled"
      loki_bucket  = var.create_loki_bucket ? module.observability_s3.loki_bucket_name : "disabled"
      tempo_bucket = var.create_tempo_bucket ? module.observability_s3.tempo_bucket_name : "disabled"
      kms_key_id   = var.create_kms_key ? module.observability_s3.kms_key_id : "disabled"
    }

    # Security configuration
    security = {
      mimir_role   = var.create_mimir_role ? module.observability_iam.mimir_role_arn : "disabled"
      loki_role    = var.create_loki_role ? module.observability_iam.loki_role_arn : "disabled"
      grafana_role = var.create_grafana_role ? module.observability_iam.grafana_role_arn : "disabled"
      tempo_role   = var.create_tempo_role ? module.observability_iam.tempo_role_arn : "disabled"
    }

    # Cost optimization settings
    cost_optimization = {
      billing_mode           = "PAY_PER_REQUEST"
      metrics_retention_days = 30
      logs_retention_days    = 7
      traces_retention_days  = 3
      pitr_enabled           = false
      monitoring_enabled     = false
    }

    # Kubernetes service account annotations
    kubernetes_service_accounts = {
      mimir   = var.create_mimir_role ? "eks.amazonaws.com/role-arn: ${module.observability_iam.mimir_role_arn}" : "disabled"
      loki    = var.create_loki_role ? "eks.amazonaws.com/role-arn: ${module.observability_iam.loki_role_arn}" : "disabled"
      grafana = var.create_grafana_role ? "eks.amazonaws.com/role-arn: ${module.observability_iam.grafana_role_arn}" : "disabled"
      tempo   = var.create_tempo_role ? "eks.amazonaws.com/role-arn: ${module.observability_iam.tempo_role_arn}" : "disabled"
    }
  }
}

# ==========================================
# Kubernetes Integration Helpers
# ==========================================

output "kubernetes_service_account_annotations" {
  description = "Service account annotations for Kubernetes deployments"
  value = {
    mimir = {
      "eks.amazonaws.com/role-arn" = module.observability_iam.mimir_role_arn
    }
    loki = {
      "eks.amazonaws.com/role-arn" = module.observability_iam.loki_role_arn
    }
    grafana = {
      "eks.amazonaws.com/role-arn" = module.observability_iam.grafana_role_arn
    }
    tempo = {
      "eks.amazonaws.com/role-arn" = module.observability_iam.tempo_role_arn
    }
  }
}

output "helm_values_mimir" {
  description = "Helm values snippet for Mimir configuration"
  value = {
    serviceAccount = {
      create = false
      name   = "mimir"
      annotations = {
        "eks.amazonaws.com/role-arn" = module.observability_iam.mimir_role_arn
      }
    }
    mimir = {
      storage = {
        backend = "s3"
        s3 = {
          bucket_name = module.observability_s3.mimir_bucket_name
          region      = var.aws_region
        }
      }
      indexGateway = {
        storage = {
          type = "dynamodb"
          dynamodb = {
            table_name = module.observability_dynamodb.mimir_table_name
            region     = var.aws_region
          }
        }
      }
    }
  }
}

output "helm_values_loki" {
  description = "Helm values snippet for Loki configuration"
  value = {
    serviceAccount = {
      create = false
      name   = "loki"
      annotations = {
        "eks.amazonaws.com/role-arn" = module.observability_iam.loki_role_arn
      }
    }
    loki = {
      storage = {
        type = "s3"
        bucketNames = {
          chunks = module.observability_s3.loki_bucket_name
          ruler  = module.observability_s3.loki_bucket_name
          admin  = module.observability_s3.loki_bucket_name
        }
        s3 = {
          region = var.aws_region
        }
      }
      schemaConfig = {
        configs = [
          {
            from = "2024-04-01"
            store = "tsdb"
            object_store = "s3"
            schema = "v13"
            index = {
              prefix = "loki_index_"
              period = "24h"
            }
          }
        ]
      }
    }
  }
}

# ==========================================
# Grafana Module Outputs
# ==========================================

output "grafana_outputs" {
  description = "Grafana module outputs for development"
  value = {
    dashboard_uids     = module.observability_grafana.dashboard_uids
    dashboard_urls     = module.observability_grafana.dashboard_urls
    folder_uid         = module.observability_grafana.folder_uid
    data_source_config = module.observability_grafana.data_source_config
    module_config      = module.observability_grafana.module_config
  }
}

# Individual Grafana outputs for convenience
output "grafana_dashboard_uids" {
  description = "UIDs of created Grafana dashboards"
  value       = module.observability_grafana.dashboard_uids
}

output "grafana_folder_uid" {
  description = "UID of the Grafana folder containing observability dashboards"
  value       = module.observability_grafana.folder_uid
}

output "grafana_workspace_endpoint" {
  description = "Grafana workspace endpoint (if managed workspace is created)"
  value       = module.observability_grafana.workspace_endpoint
}
