# ===============================================================================
# KMS KEY OUTPUTS
# ===============================================================================

output "kms_key_id" {
  description = "ID of the KMS key used for S3 encryption"
  value       = var.create_kms_key ? aws_kms_key.s3_encryption[0].key_id : null
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for S3 encryption"
  value       = var.create_kms_key ? aws_kms_key.s3_encryption[0].arn : var.existing_kms_key_arn
}

output "kms_key_alias" {
  description = "Alias of the KMS key used for S3 encryption"
  value       = var.create_kms_key ? aws_kms_alias.s3_encryption[0].name : null
}

# ===============================================================================
# MIMIR BUCKET OUTPUTS
# ===============================================================================

output "mimir_bucket_id" {
  description = "ID of the Mimir S3 bucket"
  value       = var.create_mimir_bucket ? module.mimir_bucket[0].s3_bucket_id : null
}

output "mimir_bucket_arn" {
  description = "ARN of the Mimir S3 bucket"
  value       = var.create_mimir_bucket ? module.mimir_bucket[0].s3_bucket_arn : null
}

output "mimir_bucket_name" {
  description = "Name of the Mimir S3 bucket"
  value       = var.create_mimir_bucket ? module.mimir_bucket[0].s3_bucket_id : null
}

output "mimir_bucket_region" {
  description = "Region of the Mimir S3 bucket"
  value       = var.create_mimir_bucket ? module.mimir_bucket[0].s3_bucket_region : null
}

output "mimir_bucket_domain_name" {
  description = "Domain name of the Mimir S3 bucket"
  value       = var.create_mimir_bucket ? module.mimir_bucket[0].s3_bucket_bucket_domain_name : null
}

# ===============================================================================
# LOKI BUCKET OUTPUTS
# ===============================================================================

output "loki_bucket_id" {
  description = "ID of the Loki S3 bucket"
  value       = var.create_loki_bucket ? module.loki_bucket[0].s3_bucket_id : null
}

output "loki_bucket_arn" {
  description = "ARN of the Loki S3 bucket"
  value       = var.create_loki_bucket ? module.loki_bucket[0].s3_bucket_arn : null
}

output "loki_bucket_name" {
  description = "Name of the Loki S3 bucket"
  value       = var.create_loki_bucket ? module.loki_bucket[0].s3_bucket_id : null
}

output "loki_bucket_region" {
  description = "Region of the Loki S3 bucket"
  value       = var.create_loki_bucket ? module.loki_bucket[0].s3_bucket_region : null
}

output "loki_bucket_domain_name" {
  description = "Domain name of the Loki S3 bucket"
  value       = var.create_loki_bucket ? module.loki_bucket[0].s3_bucket_bucket_domain_name : null
}

# ===============================================================================
# TEMPO BUCKET OUTPUTS
# ===============================================================================

output "tempo_bucket_id" {
  description = "ID of the Tempo S3 bucket"
  value       = var.create_tempo_bucket ? module.tempo_bucket[0].s3_bucket_id : null
}

output "tempo_bucket_arn" {
  description = "ARN of the Tempo S3 bucket"
  value       = var.create_tempo_bucket ? module.tempo_bucket[0].s3_bucket_arn : null
}

output "tempo_bucket_name" {
  description = "Name of the Tempo S3 bucket"
  value       = var.create_tempo_bucket ? module.tempo_bucket[0].s3_bucket_id : null
}

output "tempo_bucket_region" {
  description = "Region of the Tempo S3 bucket"
  value       = var.create_tempo_bucket ? module.tempo_bucket[0].s3_bucket_region : null
}

# ===============================================================================
# ACCESS LOGS BUCKET OUTPUTS
# ===============================================================================

output "access_logs_bucket_id" {
  description = "ID of the access logs S3 bucket"
  value       = var.enable_access_logging && var.access_log_bucket_name == null ? module.access_logs_bucket[0].s3_bucket_id : var.access_log_bucket_name
}

output "access_logs_bucket_arn" {
  description = "ARN of the access logs S3 bucket"
  value       = var.enable_access_logging && var.access_log_bucket_name == null ? module.access_logs_bucket[0].s3_bucket_arn : null
}

# ===============================================================================
# BUCKET SUMMARY FOR INTEGRATION
# ===============================================================================

output "buckets_summary" {
  description = "Summary of all created S3 buckets for integration with other modules"
  value = {
    mimir = var.create_mimir_bucket ? {
      bucket_name = module.mimir_bucket[0].s3_bucket_id
      bucket_arn  = module.mimir_bucket[0].s3_bucket_arn
      region      = module.mimir_bucket[0].s3_bucket_region
      purpose     = "metrics-storage"
      encryption  = "kms"
    } : null

    loki = var.create_loki_bucket ? {
      bucket_name = module.loki_bucket[0].s3_bucket_id
      bucket_arn  = module.loki_bucket[0].s3_bucket_arn
      region      = module.loki_bucket[0].s3_bucket_region
      purpose     = "logs-storage"
      encryption  = "kms"
    } : null

    tempo = var.create_tempo_bucket ? {
      bucket_name = module.tempo_bucket[0].s3_bucket_id
      bucket_arn  = module.tempo_bucket[0].s3_bucket_arn
      region      = module.tempo_bucket[0].s3_bucket_region
      purpose     = "traces-storage"
      encryption  = "kms"
    } : null
  }
}

# ===============================================================================
# BUCKET CONFIGURATIONS FOR APPLICATIONS
# ===============================================================================

output "mimir_s3_config" {
  description = "S3 configuration block for Mimir application"
  value = var.create_mimir_bucket ? {
    bucket_name = module.mimir_bucket[0].s3_bucket_id
    region      = module.mimir_bucket[0].s3_bucket_region
    encryption = {
      type        = "kms"
      kms_key_arn = var.create_kms_key ? aws_kms_key.s3_encryption[0].arn : var.existing_kms_key_arn
    }
    endpoint = "https://s3.${module.mimir_bucket[0].s3_bucket_region}.amazonaws.com"
  } : null
}

output "loki_s3_config" {
  description = "S3 configuration block for Loki application"
  value = var.create_loki_bucket ? {
    bucket_name = module.loki_bucket[0].s3_bucket_id
    region      = module.loki_bucket[0].s3_bucket_region
    encryption = {
      type        = "kms"
      kms_key_arn = var.create_kms_key ? aws_kms_key.s3_encryption[0].arn : var.existing_kms_key_arn
    }
    endpoint = "https://s3.${module.loki_bucket[0].s3_bucket_region}.amazonaws.com"
  } : null
}

output "tempo_s3_config" {
  description = "S3 configuration block for Tempo application"
  value = var.create_tempo_bucket ? {
    bucket_name = module.tempo_bucket[0].s3_bucket_id
    region      = module.tempo_bucket[0].s3_bucket_region
    encryption = {
      type        = "kms"
      kms_key_arn = var.create_kms_key ? aws_kms_key.s3_encryption[0].arn : var.existing_kms_key_arn
    }
    endpoint = "https://s3.${module.tempo_bucket[0].s3_bucket_region}.amazonaws.com"
  } : null
}

# ===============================================================================
# BUCKET NAMES FOR QUICK REFERENCE
# ===============================================================================

output "bucket_names" {
  description = "Map of all bucket names for quick reference"
  value = {
    mimir       = var.create_mimir_bucket ? module.mimir_bucket[0].s3_bucket_id : null
    loki        = var.create_loki_bucket ? module.loki_bucket[0].s3_bucket_id : null
    tempo       = var.create_tempo_bucket ? module.tempo_bucket[0].s3_bucket_id : null
    access_logs = var.enable_access_logging && var.access_log_bucket_name == null ? module.access_logs_bucket[0].s3_bucket_id : var.access_log_bucket_name
  }
}

# ===============================================================================
# BUCKET ARNS FOR IAM POLICIES
# ===============================================================================

output "bucket_arns" {
  description = "Map of all bucket ARNs for IAM policy creation"
  value = {
    mimir       = var.create_mimir_bucket ? module.mimir_bucket[0].s3_bucket_arn : null
    loki        = var.create_loki_bucket ? module.loki_bucket[0].s3_bucket_arn : null
    tempo       = var.create_tempo_bucket ? module.tempo_bucket[0].s3_bucket_arn : null
    access_logs = var.enable_access_logging && var.access_log_bucket_name == null ? module.access_logs_bucket[0].s3_bucket_arn : null
  }
}
