# ===============================================================================
# CORE VARIABLES
# ===============================================================================

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "observability"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ===============================================================================
# BUCKET CREATION FLAGS
# ===============================================================================

variable "create_mimir_bucket" {
  description = "Whether to create S3 bucket for Mimir metrics storage"
  type        = bool
  default     = true
}

variable "create_loki_bucket" {
  description = "Whether to create S3 bucket for Loki logs storage"
  type        = bool
  default     = false
}

variable "create_tempo_bucket" {
  description = "Whether to create S3 bucket for Tempo traces storage"
  type        = bool
  default     = false
}

# ===============================================================================
# KMS ENCRYPTION CONFIGURATION
# ===============================================================================

variable "create_kms_key" {
  description = "Whether to create a new KMS key for S3 encryption"
  type        = bool
  default     = true
}

variable "existing_kms_key_arn" {
  description = "ARN of existing KMS key to use for S3 encryption (if create_kms_key is false)"
  type        = string
  default     = null
}

variable "enable_key_rotation" {
  description = "Whether to enable automatic KMS key rotation"
  type        = bool
  default     = true
}

variable "kms_deletion_window_in_days" {
  description = "Number of days after which the KMS key is deleted after destruction"
  type        = number
  default     = 30

  validation {
    condition     = var.kms_deletion_window_in_days >= 7 && var.kms_deletion_window_in_days <= 30
    error_message = "KMS deletion window must be between 7 and 30 days."
  }
}

# ===============================================================================
# BUCKET CONFIGURATION
# ===============================================================================

variable "enable_versioning" {
  description = "Whether to enable S3 bucket versioning"
  type        = bool
  default     = true
}

variable "enable_lifecycle_management" {
  description = "Whether to enable S3 lifecycle management for cost optimization"
  type        = bool
  default     = true
}

variable "noncurrent_version_retention_days" {
  description = "Number of days to retain noncurrent object versions"
  type        = number
  default     = 90
}

# ===============================================================================
# DATA RETENTION POLICIES
# ===============================================================================

variable "logs_retention_days" {
  description = "Number of days to retain log data (0 = infinite retention)"
  type        = number
  default     = 0
}

variable "traces_retention_days" {
  description = "Number of days to retain trace data (0 = infinite retention)"
  type        = number
  default     = 0
}

variable "access_logs_retention_days" {
  description = "Number of days to retain access logs"
  type        = number
  default     = 30
}

# ===============================================================================
# CORS CONFIGURATION
# ===============================================================================

variable "enable_cors" {
  description = "Whether to enable CORS configuration for buckets"
  type        = bool
  default     = false
}

variable "cors_allowed_origins" {
  description = "List of allowed origins for CORS"
  type        = list(string)
  default     = ["*"]
}

# ===============================================================================
# ACCESS LOGGING CONFIGURATION
# ===============================================================================

variable "enable_access_logging" {
  description = "Whether to enable S3 access logging"
  type        = bool
  default     = false
}

variable "access_log_bucket_name" {
  description = "Name of existing S3 bucket for access logs (if null, will create new bucket)"
  type        = string
  default     = null
}

# ===============================================================================
# NOTIFICATIONS CONFIGURATION
# ===============================================================================

variable "enable_notifications" {
  description = "Whether to enable S3 event notifications"
  type        = bool
  default     = false
}

variable "sns_topic_arn" {
  description = "ARN of SNS topic for S3 event notifications"
  type        = string
  default     = null
}

# ===============================================================================
# BUCKET POLICY CONFIGURATION
# ===============================================================================

variable "bucket_policy_statements" {
  description = "Additional IAM policy statements to add to bucket policies"
  type = list(object({
    sid       = string
    effect    = string
    actions   = list(string)
    resources = list(string)
    principals = optional(object({
      type        = string
      identifiers = list(string)
    }))
    condition = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })))
  }))
  default = []
}

# ===============================================================================
# MULTI-REGION CONFIGURATION
# ===============================================================================

variable "enable_cross_region_replication" {
  description = "Whether to enable cross-region replication"
  type        = bool
  default     = false
}

variable "replication_destination_bucket" {
  description = "Destination bucket for cross-region replication"
  type        = string
  default     = null
}

variable "replication_destination_region" {
  description = "Destination region for cross-region replication"
  type        = string
  default     = null
}

# ===============================================================================
# PERFORMANCE CONFIGURATION
# ===============================================================================

variable "request_payer" {
  description = "Specifies who should bear the cost of Amazon S3 data transfer"
  type        = string
  default     = "BucketOwner"

  validation {
    condition     = contains(["BucketOwner", "Requester"], var.request_payer)
    error_message = "Request payer must be either 'BucketOwner' or 'Requester'."
  }
}

variable "object_lock_enabled" {
  description = "Whether to enable S3 Object Lock for compliance"
  type        = bool
  default     = false
}

variable "object_lock_configuration" {
  description = "S3 Object Lock configuration"
  type = object({
    mode  = string
    days  = optional(number)
    years = optional(number)
  })
  default = null
}

# ===============================================================================
# COST OPTIMIZATION
# ===============================================================================

variable "intelligent_tiering_enabled" {
  description = "Whether to enable S3 Intelligent Tiering"
  type        = bool
  default     = false
}

variable "intelligent_tiering_filter_prefix" {
  description = "Object key prefix for intelligent tiering"
  type        = string
  default     = ""
}

variable "transfer_acceleration_enabled" {
  description = "Whether to enable S3 Transfer Acceleration"
  type        = bool
  default     = false
}
