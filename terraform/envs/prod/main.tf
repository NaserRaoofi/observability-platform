# Production Environment Configuration

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
    }
  }
}

# Local values
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# Production DynamoDB configuration with autoscaling
module "dynamodb" {
  source = "../../modules/dynamodb"

  environment  = var.environment
  project_name = var.project_name

  # Use PROVISIONED for production with autoscaling
  billing_mode   = "PROVISIONED"
  read_capacity  = 10
  write_capacity = 10

  # Enable autoscaling for production
  autoscaling_enabled = true
  autoscaling_read = {
    min_capacity = 5
    max_capacity = 1000
  }
  autoscaling_write = {
    min_capacity = 5
    max_capacity = 1000
  }

  # Encryption (KMS key will be created by s3-kms module)
  # kms_key_arn                    = module.s3_kms.kms_key_arn
  server_side_encryption_enabled = true

  # Backup
  point_in_time_recovery_enabled = true

  tags = local.common_tags
}

# Output the DynamoDB table information
output "dynamodb_mimir_table_name" {
  description = "Name of the Mimir DynamoDB table"
  value       = module.dynamodb.mimir_table_name
}

output "dynamodb_mimir_table_arn" {
  description = "ARN of the Mimir DynamoDB table"
  value       = module.dynamodb.mimir_table_arn
}

output "dynamodb_loki_table_name" {
  description = "Name of the Loki DynamoDB table (production only)"
  value       = module.dynamodb.loki_table_name
}
