# Test configuration for DynamoDB module
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Test the DynamoDB module locally
module "test_monitoring_dynamodb" {
  source = "./"

  # Basic configuration
  environment  = "test"
  project_name = "monitoring-test"

  # Create both tables for testing
  create_mimir_table = true
  create_loki_table  = true

  # Use on-demand billing for testing (no capacity planning needed)
  billing_mode = "PAY_PER_REQUEST"

  # Security settings
  server_side_encryption_enabled = true
  point_in_time_recovery_enabled = false  # Disabled for cost in testing

  # Test tags
  tags = {
    Environment = "test"
    Purpose     = "module-validation"
    CreatedBy   = "terraform"
  }
}

# Outputs for validation
output "test_mimir_table_name" {
  description = "Name of the test Mimir table"
  value       = module.test_monitoring_dynamodb.mimir_table_name
}

output "test_mimir_table_arn" {
  description = "ARN of the test Mimir table"
  value       = module.test_monitoring_dynamodb.mimir_table_arn
}

output "test_loki_table_name" {
  description = "Name of the test Loki table"
  value       = module.test_monitoring_dynamodb.loki_table_name
}

output "test_loki_table_arn" {
  description = "ARN of the test Loki table"
  value       = module.test_monitoring_dynamodb.loki_table_arn
}
