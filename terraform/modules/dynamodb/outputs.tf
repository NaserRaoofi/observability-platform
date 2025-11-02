# Mimir DynamoDB table outputs (conditional)
output "mimir_table_name" {
  description = "Name of the Mimir DynamoDB table"
  value       = length(module.mimir_index_table) > 0 ? module.mimir_index_table[0].table_name : null
}

output "mimir_table_id" {
  description = "ID of the Mimir DynamoDB table"
  value       = length(module.mimir_index_table) > 0 ? module.mimir_index_table[0].table_id : null
}

output "mimir_table_arn" {
  description = "ARN of the Mimir DynamoDB table"
  value       = length(module.mimir_index_table) > 0 ? module.mimir_index_table[0].table_arn : null
}

output "mimir_table_stream_arn" {
  description = "ARN of the Mimir DynamoDB table stream"
  value       = length(module.mimir_index_table) > 0 ? module.mimir_index_table[0].table_stream_arn : null
}

output "mimir_table_stream_label" {
  description = "Timestamp of the Mimir DynamoDB table stream"
  value       = length(module.mimir_index_table) > 0 ? module.mimir_index_table[0].table_stream_label : null
}

# Loki DynamoDB table outputs (conditional)
output "loki_table_name" {
  description = "Name of the Loki DynamoDB table"
  value       = length(module.loki_index_table) > 0 ? module.loki_index_table[0].table_name : null
}

output "loki_table_id" {
  description = "ID of the Loki DynamoDB table"
  value       = length(module.loki_index_table) > 0 ? module.loki_index_table[0].table_id : null
}

output "loki_table_arn" {
  description = "ARN of the Loki DynamoDB table"
  value       = length(module.loki_index_table) > 0 ? module.loki_index_table[0].table_arn : null
}

# Global Secondary Index outputs
output "mimir_global_secondary_indexes" {
  description = "Global Secondary Indexes of the Mimir table"
  value       = length(module.mimir_index_table) > 0 ? module.mimir_index_table[0].global_secondary_index_names : []
}

# Table endpoints for VPC access
output "mimir_table_endpoint" {
  description = "DynamoDB endpoint for the Mimir table"
  value = length(module.mimir_index_table) > 0 ? {
    table_name = module.mimir_index_table[0].table_name
    region     = data.aws_region.current.id
  } : null
}

output "loki_table_endpoint" {
  description = "DynamoDB endpoint for the Loki table"
  value = length(module.loki_index_table) > 0 ? {
    table_name = module.loki_index_table[0].table_name
    region     = data.aws_region.current.id
  } : null
}
