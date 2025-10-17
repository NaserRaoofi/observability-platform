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
# EKS CLUSTER CONFIGURATION
# ===============================================================================

variable "eks_oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider"
  type        = string
}

variable "monitoring_namespace" {
  description = "Kubernetes namespace where monitoring services are deployed"
  type        = string
  default     = "monitoring"
}

# ===============================================================================
# DYNAMODB TABLE ARNS (from DynamoDB module outputs)
# ===============================================================================

variable "mimir_table_arn" {
  description = "ARN of the Mimir DynamoDB table"
  type        = string
}

variable "loki_table_arn" {
  description = "ARN of the Loki DynamoDB table (optional)"
  type        = string
  default     = null
}

# ===============================================================================
# S3 BUCKET ARNS (for object storage)
# ===============================================================================

variable "mimir_s3_bucket_arn" {
  description = "ARN of the S3 bucket for Mimir object storage"
  type        = string
}

variable "loki_s3_bucket_arn" {
  description = "ARN of the S3 bucket for Loki object storage (optional)"
  type        = string
  default     = null
}

# ===============================================================================
# FEATURE FLAGS
# ===============================================================================

variable "create_loki_resources" {
  description = "Whether to create Loki-related IAM resources"
  type        = bool
  default     = false
}

variable "create_grafana_resources" {
  description = "Whether to create Grafana-related IAM resources"
  type        = bool
  default     = true
}

# ===============================================================================
# ADDITIONAL SERVICE CONFIGURATION
# ===============================================================================

variable "additional_oidc_providers" {
  description = "Additional OIDC providers for multi-cluster setup"
  type = map(object({
    provider_arn               = string
    namespace_service_accounts = list(string)
  }))
  default = {}
}

variable "enable_cross_account_access" {
  description = "Enable cross-account access for roles"
  type        = bool
  default     = false
}

variable "trusted_account_ids" {
  description = "List of AWS account IDs that can assume these roles"
  type        = list(string)
  default     = []
}

# ===============================================================================
# PERMISSIONS CONFIGURATION
# ===============================================================================

variable "mimir_additional_policies" {
  description = "Additional policy ARNs to attach to Mimir role"
  type        = map(string)
  default     = {}
}

variable "loki_additional_policies" {
  description = "Additional policy ARNs to attach to Loki role"
  type        = map(string)
  default     = {}
}

variable "grafana_additional_policies" {
  description = "Additional policy ARNs to attach to Grafana role"
  type        = map(string)
  default     = {}
}
