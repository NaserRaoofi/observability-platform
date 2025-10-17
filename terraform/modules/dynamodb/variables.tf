# Environment and naming
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "observability"
}

# DynamoDB Configuration
variable "mimir_table_name" {
  description = "Name for the Mimir index table"
  type        = string
  default     = null
}

variable "billing_mode" {
  description = "DynamoDB billing mode (PAY_PER_REQUEST or PROVISIONED)"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "read_capacity" {
  description = "Read capacity units (only used when billing_mode is PROVISIONED)"
  type        = number
  default     = 5
}

variable "write_capacity" {
  description = "Write capacity units (only used when billing_mode is PROVISIONED)"
  type        = number
  default     = 5
}

# Encryption
variable "kms_key_arn" {
  description = "ARN of KMS key for DynamoDB encryption"
  type        = string
  default     = null
}

variable "server_side_encryption_enabled" {
  description = "Enable server-side encryption for DynamoDB"
  type        = bool
  default     = true
}

# Backup and recovery
variable "point_in_time_recovery_enabled" {
  description = "Enable point-in-time recovery for DynamoDB"
  type        = bool
  default     = true
}

# Autoscaling (for PROVISIONED billing mode)
variable "autoscaling_enabled" {
  description = "Enable autoscaling for DynamoDB table"
  type        = bool
  default     = false
}

variable "autoscaling_read" {
  description = "Autoscaling configuration for read capacity"
  type = object({
    min_capacity = number
    max_capacity = number
  })
  default = {
    min_capacity = 5
    max_capacity = 100
  }
}

variable "autoscaling_write" {
  description = "Autoscaling configuration for write capacity"
  type = object({
    min_capacity = number
    max_capacity = number
  })
  default = {
    min_capacity = 5
    max_capacity = 100
  }
}

# Global Secondary Indexes
variable "global_secondary_indexes" {
  description = "List of global secondary indexes"
  type = list(object({
    name            = string
    hash_key        = string
    range_key       = optional(string)
    projection_type = string
    read_capacity   = optional(number)
    write_capacity  = optional(number)
  }))
  default = []
}

# Tags
variable "tags" {
  description = "Additional tags for DynamoDB tables"
  type        = map(string)
  default     = {}
}

# Table creation flags
variable "create_mimir_table" {
  description = "Whether to create the Mimir metrics table"
  type        = bool
  default     = true
}

variable "create_loki_table" {
  description = "Whether to create the Loki logs index table"
  type        = bool
  default     = false
}
