# Environment configuration
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "observability"
}

# ===============================================================================
# EKS CLUSTER CONFIGURATION
# ===============================================================================

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "eks_oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider"
  type        = string
}

# ===============================================================================
# KUBERNETES NAMESPACES
# ===============================================================================

variable "monitoring_namespace" {
  description = "Kubernetes namespace for monitoring services"
  type        = string
  default     = "monitoring"
}

variable "logging_namespace" {
  description = "Kubernetes namespace for logging services"
  type        = string
  default     = "logging"
}

variable "tracing_namespace" {
  description = "Kubernetes namespace for tracing services"
  type        = string
  default     = "tracing"
}

# ===============================================================================
# DYNAMODB SERVICE ENABLEMENT
# ===============================================================================

variable "create_mimir_table" {
  description = "Whether to create Mimir DynamoDB table"
  type        = bool
  default     = true
}

variable "create_loki_table" {
  description = "Whether to create Loki DynamoDB table"
  type        = bool
  default     = true
}

# DynamoDB specific variables
variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode"
  type        = string
  default     = "PAY_PER_REQUEST"
}

# ===============================================================================
# S3 BUCKET ENABLEMENT
# ===============================================================================

variable "create_mimir_bucket" {
  description = "Whether to create Mimir S3 bucket"
  type        = bool
  default     = true
}

variable "create_loki_bucket" {
  description = "Whether to create Loki S3 bucket"
  type        = bool
  default     = true
}

variable "create_tempo_bucket" {
  description = "Whether to create Tempo S3 bucket"
  type        = bool
  default     = false
}

variable "create_kms_key" {
  description = "Whether to create KMS key for encryption"
  type        = bool
  default     = true
}

# ===============================================================================
# IAM ROLE ENABLEMENT
# ===============================================================================

variable "create_mimir_role" {
  description = "Whether to create IAM role for Mimir"
  type        = bool
  default     = true
}

variable "create_loki_role" {
  description = "Whether to create IAM role for Loki"
  type        = bool
  default     = true
}

variable "create_grafana_role" {
  description = "Whether to create IAM role for Grafana"
  type        = bool
  default     = true
}

# ===============================================================================
# GRAFANA CONFIGURATION
# ===============================================================================

variable "enable_grafana_dashboards" {
  description = "Whether to create Grafana dashboards"
  type        = bool
  default     = true
}

variable "grafana_org_id" {
  description = "Grafana organization ID"
  type        = string
  default     = "1"
}

variable "create_grafana_workspace" {
  description = "Whether to create a managed Grafana workspace"
  type        = bool
  default     = false
}

variable "prometheus_endpoint" {
  description = "Prometheus endpoint URL for Grafana data source"
  type        = string
  default     = "http://prometheus.monitoring.svc.cluster.local:9090"
}

variable "alertmanager_endpoint" {
  description = "AlertManager endpoint URL for Grafana data source"
  type        = string
  default     = "http://alertmanager.monitoring.svc.cluster.local:9093"
}

variable "create_tempo_role" {
  description = "Whether to create IAM role for Tempo"
  type        = bool
  default     = false
}

# Tags
variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
