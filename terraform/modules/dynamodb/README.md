# DynamoDB Module

This Terraform module creates DynamoDB tables for observability infrastructure, specifically designed for metrics and logs indexing. It uses the [CloudPosse DynamoDB module](https://github.com/cloudposse/terraform-aws-dynamodb) as a remote module for best practices.

## Features

- **Flexible Table Creation**: Choose which tables to create (Mimir, Loki, or both)
- **CloudPosse Integration**: Uses proven CloudPosse DynamoDB module
- **Production Ready**: Encryption, backup, autoscaling support
- **Cost Optimized**: PAY_PER_REQUEST billing by default
- **Monitoring Ready**: Proper tagging and naming conventions

## Usage

### Basic Usage

```hcl
module "dynamodb" {
  source = "./modules/dynamodb"

  environment  = "dev"
  project_name = "observability"

  # Encryption
  kms_key_arn                    = module.kms.key_arn
  server_side_encryption_enabled = true

  # Backup
  point_in_time_recovery_enabled = true

  tags = {
    Environment = "dev"
    Project     = "observability"
  }
}
```

### Advanced Usage with Provisioned Billing

```hcl
module "dynamodb" {
  source = "./modules/dynamodb"

  environment  = "prod"
  project_name = "observability"

  # Billing configuration
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20

  # Autoscaling
  autoscaling_enabled = true
  autoscaling_read = {
    min_capacity = 5
    max_capacity = 1000
  }
  autoscaling_write = {
    min_capacity = 5
    max_capacity = 1000
  }

  # Additional GSI
  global_secondary_indexes = [
    {
      name            = "custom-index"
      hash_key        = "custom_key"
      projection_type = "KEYS_ONLY"
      read_capacity   = 5
      write_capacity  = 5
    }
  ]

  # Encryption
  kms_key_arn                    = module.kms.key_arn
  server_side_encryption_enabled = true

  tags = {
    Environment = "prod"
    Project     = "observability"
  }
}
```

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | >= 1.0  |
| aws       | ~> 5.0  |

## Providers

| Name | Version |
| ---- | ------- |
| aws  | ~> 5.0  |

## Modules

| Name              | Source                  | Version   |
| ----------------- | ----------------------- | --------- |
| mimir_index_table | cloudposse/dynamodb/aws | ~> 0.35.0 |
| loki_index_table  | cloudposse/dynamodb/aws | ~> 0.35.0 |

## Resources

No additional resources created directly by this module.

## Inputs

| Name                           | Description                                                       | Type           | Default             | Required |
| ------------------------------ | ----------------------------------------------------------------- | -------------- | ------------------- | :------: |
| environment                    | Environment name (dev, staging, prod)                             | `string`       | n/a                 |   yes    |
| project_name                   | Name of the project                                               | `string`       | `"observability"`   |    no    |
| mimir_table_name               | Name for the Mimir index table                                    | `string`       | `null`              |    no    |
| billing_mode                   | DynamoDB billing mode (PAY_PER_REQUEST or PROVISIONED)            | `string`       | `"PAY_PER_REQUEST"` |    no    |
| read_capacity                  | Read capacity units (only used when billing_mode is PROVISIONED)  | `number`       | `5`                 |    no    |
| write_capacity                 | Write capacity units (only used when billing_mode is PROVISIONED) | `number`       | `5`                 |    no    |
| kms_key_arn                    | ARN of KMS key for DynamoDB encryption                            | `string`       | `null`              |    no    |
| server_side_encryption_enabled | Enable server-side encryption for DynamoDB                        | `bool`         | `true`              |    no    |
| point_in_time_recovery_enabled | Enable point-in-time recovery for DynamoDB                        | `bool`         | `true`              |    no    |
| autoscaling_enabled            | Enable autoscaling for DynamoDB table                             | `bool`         | `false`             |    no    |
| global_secondary_indexes       | List of global secondary indexes                                  | `list(object)` | `[]`                |    no    |
| tags                           | Additional tags for DynamoDB tables                               | `map(string)`  | `{}`                |    no    |

## Outputs

| Name                           | Description                                 |
| ------------------------------ | ------------------------------------------- |
| mimir_table_name               | Name of the Mimir DynamoDB table            |
| mimir_table_id                 | ID of the Mimir DynamoDB table              |
| mimir_table_arn                | ARN of the Mimir DynamoDB table             |
| mimir_table_stream_arn         | ARN of the Mimir DynamoDB table stream      |
| mimir_global_secondary_indexes | Global Secondary Indexes of the Mimir table |
| loki_table_name                | Name of the Loki DynamoDB table             |
| loki_table_arn                 | ARN of the Loki DynamoDB table              |

## Why CloudPosse Module?

This module uses the CloudPosse DynamoDB Terraform module for several reasons:

1. **Best Practices**: CloudPosse modules follow Terraform best practices
2. **Maintenance**: Well-maintained and regularly updated
3. **Features**: Comprehensive feature set including autoscaling, encryption, etc.
4. **Community**: Large community adoption and testing
5. **Documentation**: Excellent documentation and examples

## Mimir Configuration

The created DynamoDB table is configured specifically for Mimir's needs:

- **Hash Key**: `id` - Primary partition key
- **Range Key**: `range_key` - Sort key for efficient queries
- **GSI**: `range-index` - Global Secondary Index for reverse lookups
- **Encryption**: KMS encryption enabled by default
- **Backup**: Point-in-time recovery enabled

## Example Mimir Configuration

```yaml
# mimir.yaml
blocks_storage:
  backend: s3
  s3:
    bucket_name: observability-mimir-bucket

index_queries:
  backend: dynamodb
  dynamodb:
    original_table_name: observability-mimir-index-dev
```
