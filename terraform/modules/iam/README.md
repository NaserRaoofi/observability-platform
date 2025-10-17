# IAM Module for Observability Stack

This Terraform module creates IAM roles and policies for observability services (Mimir, Loki, Grafana) to securely access AWS resources using IRSA (IAM Roles for Service Accounts).

## Features

- **🔐 IRSA Integration** - Native Kubernetes service account integration
- **📊 Mimir Support** - DynamoDB and S3 access for metrics storage
- **📋 Loki Support** - DynamoDB and S3 access for logs storage
- **📈 Grafana Support** - Read-only access to observability data sources
- **🏢 Multi-Cluster** - Support for multiple EKS clusters
- **🔒 Least Privilege** - Minimal required permissions per service
- **🏷️ Resource Scoped** - Policies scoped to specific tables/buckets

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Kubernetes    │    │   IAM Roles      │    │  AWS Resources  │
│   Service       │────│   (IRSA)         │────│                 │
│   Accounts      │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
│                      │                      │
├─ mimir              ├─ mimir-role          ├─ DynamoDB Table
├─ loki               ├─ loki-role           ├─ S3 Buckets
└─ grafana            └─ grafana-role        └─ CloudWatch
```

## Quick Start

```hcl
module "observability_iam" {
  source = "./modules/iam"

  environment  = "prod"
  project_name = "observability"

  # EKS Configuration
  eks_oidc_provider_arn = module.eks.oidc_provider_arn
  monitoring_namespace  = "monitoring"

  # Resource ARNs from other modules
  mimir_table_arn     = module.dynamodb.mimir_table_arn
  mimir_s3_bucket_arn = module.s3.mimir_bucket_arn

  # Enable/disable services
  create_loki_resources    = true
  create_grafana_resources = true
}
```

## Permissions Created

### Mimir

- **DynamoDB**: `GetItem`, `PutItem`, `Query`, `Scan`, `UpdateItem`, `DeleteItem`
- **S3**: `GetObject`, `PutObject`, `DeleteObject`, `ListBucket`
- **CloudWatch**: Metrics publishing

### Loki

- **DynamoDB**: `GetItem`, `PutItem`, `Query`, `Scan`, `UpdateItem`, `DeleteItem`
- **S3**: `GetObject`, `PutObject`, `DeleteObject`, `ListBucket`
- **CloudWatch**: Logs publishing

### Grafana

- **CloudWatch**: Read-only metrics and logs access
- **Prometheus**: Read-only query access
- **EC2/EKS**: Resource discovery

## Usage

See [USAGE_EXAMPLES.md](./USAGE_EXAMPLES.md) for detailed examples and configurations.

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | >= 1.0  |
| aws       | >= 5.0  |

## Providers

| Name | Version |
| ---- | ------- |
| aws  | >= 5.0  |

## Dependencies

- **terraform-aws-iam** module (cloned at project root)
- **EKS cluster** with OIDC provider
- **DynamoDB tables** (created by DynamoDB module)
- **S3 buckets** (created by S3 module)

## Outputs

| Name                          | Description                            |
| ----------------------------- | -------------------------------------- |
| `mimir_role_arn`              | ARN of Mimir IAM role                  |
| `loki_role_arn`               | ARN of Loki IAM role                   |
| `grafana_role_arn`            | ARN of Grafana IAM role                |
| `service_account_annotations` | Kubernetes service account annotations |

## Security

- ✅ **Principle of Least Privilege** - Minimal required permissions
- ✅ **Resource Scoping** - Policies target specific resources
- ✅ **Namespace Isolation** - Service accounts tied to namespaces
- ✅ **Trust Policies** - Explicit OIDC provider trust relationships
