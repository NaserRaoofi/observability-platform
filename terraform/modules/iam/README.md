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

## Usage Examples

### Basic Setup - Mimir Only

```hcl
module "observability_iam" {
  source = "./modules/iam"

  # Environment configuration
  environment  = "prod"
  project_name = "observability"

  # EKS cluster configuration
  eks_oidc_provider_arn = module.eks.oidc_provider_arn
  monitoring_namespace  = "monitoring"

  # DynamoDB table ARNs (from DynamoDB module)
  mimir_table_arn = module.observability_dynamodb.mimir_table_arn

  # S3 bucket ARNs (from S3 module)
  mimir_s3_bucket_arn = module.observability_s3.mimir_bucket_arn

  # Feature flags
  create_loki_resources    = false
  create_grafana_resources = true

  tags = {
    Environment = "prod"
    Team        = "platform"
  }
}
```

### Full Observability Stack

```hcl
module "observability_iam" {
  source = "./modules/iam"

  environment  = "prod"
  project_name = "observability"

  # EKS cluster configuration
  eks_oidc_provider_arn = module.eks.oidc_provider_arn
  monitoring_namespace  = "monitoring"

  # DynamoDB table ARNs
  mimir_table_arn = module.observability_dynamodb.mimir_table_arn
  loki_table_arn  = module.observability_dynamodb.loki_table_arn

  # S3 bucket ARNs
  mimir_s3_bucket_arn = module.observability_s3.mimir_bucket_arn
  loki_s3_bucket_arn  = module.observability_s3.loki_bucket_arn
  tempo_s3_bucket_arn = module.observability_s3.tempo_bucket_arn

  # Enable all services
  create_loki_resources    = true
  create_grafana_resources = true
  create_tempo_resources   = true

  tags = {
    Environment = "prod"
    Team        = "platform"
    CostCenter  = "engineering"
  }
}
```

## Kubernetes Integration

### Service Account Configuration

After applying the IAM module, configure your Kubernetes service accounts:

```yaml
# Mimir Service Account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: mimir
  namespace: monitoring
  annotations:
    eks.amazonaws.com/role-arn: "${module.observability_iam.mimir_role_arn}"
automountServiceAccountToken: true
---
# Loki Service Account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: loki
  namespace: monitoring
  annotations:
    eks.amazonaws.com/role-arn: "${module.observability_iam.loki_role_arn}"
automountServiceAccountToken: true
---
# Grafana Service Account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: grafana
  namespace: monitoring
  annotations:
    eks.amazonaws.com/role-arn: "${module.observability_iam.grafana_role_arn}"
automountServiceAccountToken: true
```

### Helm Chart Integration

```yaml
# Mimir Helm Values
serviceAccount:
  create: true
  name: mimir
  annotations:
    eks.amazonaws.com/role-arn: "${module.observability_iam.mimir_role_arn}"

storage:
  dynamodb:
    table_name: "${module.observability_dynamodb.mimir_table_name}"
    region: "${data.aws_region.current.name}"
  s3:
    bucket: "${module.observability_s3.mimir_bucket_name}"
    region: "${data.aws_region.current.name}"
```

## IAM Roles Created

### 1. Mimir Role (`observability-mimir-{environment}`)

**Purpose**: Metrics storage and querying

**Permissions**:

- ✅ `dynamodb:PutItem` - Write metrics index data
- ✅ `dynamodb:Query` - Query metrics by time range
- ✅ `dynamodb:UpdateItem` - Update metrics metadata
- ✅ `dynamodb:DescribeTable` - Table information
- ✅ Full S3 access to metrics bucket
- ✅ CloudWatch metrics publishing

### 2. Loki Role (`observability-loki-{environment}`)

**Purpose**: Logs storage and indexing

**Permissions**:

- ✅ `dynamodb:PutItem` - Write log index data
- ✅ `dynamodb:Query` - Query logs by criteria
- ✅ `dynamodb:UpdateItem` - Update log metadata
- ✅ `dynamodb:DescribeTable` - Table information
- ✅ Full S3 access to logs bucket
- ✅ CloudWatch logs publishing

### 3. Grafana Role (`observability-grafana-{environment}`)

**Purpose**: Dashboard and visualization

**Permissions**:

- ✅ CloudWatch read-only access
- ✅ Prometheus/Mimir query access
- ✅ EC2/EKS resource discovery
- ✅ Log query permissions

### 4. Tempo Role (`observability-tempo-{environment}`)

**Purpose**: Distributed tracing storage

**Permissions**:

- ✅ Full S3 access to traces bucket
- ✅ Multipart upload support for large traces

## Troubleshooting

### Common Issues

1. **Service Account Not Working**

   - Verify OIDC provider is configured in EKS
   - Check service account annotations
   - Ensure pod spec references the correct service account

2. **Permission Denied Errors**

   - Verify IAM role trust policy allows the OIDC provider
   - Check if the namespace/service account matches the trust policy
   - Validate that policies are attached to the role

3. **DynamoDB Access Issues**
   - Confirm table ARNs are correct
   - Check if table indexes are included in permissions
   - Verify region-specific access patterns

### Debug Commands

```bash
# Check service account annotations
kubectl get sa mimir -n monitoring -o yaml

# Verify pod is using the service account
kubectl get pod <mimir-pod> -n monitoring -o yaml | grep serviceAccount

# Test AWS credentials in pod
kubectl exec -it <mimir-pod> -n monitoring -- env | grep AWS

# Test AWS API access
kubectl exec -it <mimir-pod> -n monitoring -- aws sts get-caller-identity
```

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

- **EKS cluster** with OIDC provider configured
- **DynamoDB tables** (created by DynamoDB module)
- **S3 buckets** (created by S3 module)

## Outputs

| Name                          | Description                            |
| ----------------------------- | -------------------------------------- |
| `mimir_role_arn`              | ARN of Mimir IAM role                  |
| `loki_role_arn`               | ARN of Loki IAM role (if created)      |
| `grafana_role_arn`            | ARN of Grafana IAM role (if created)   |
| `tempo_role_arn`              | ARN of Tempo IAM role (if created)     |
| `service_account_annotations` | Kubernetes service account annotations |

## Security Best Practices

- ✅ **Principle of Least Privilege** - Each service gets only required permissions
- ✅ **Resource Scoping** - Policies target specific tables/buckets
- ✅ **Namespace Isolation** - Service accounts tied to specific namespaces
- ✅ **Trust Relationships** - Explicit OIDC provider trust policies
- ✅ **Cross-Account Controls** - Optional cross-account access with explicit trust
- ✅ **Audit Ready** - All permissions documented and traceable

## Key Benefits

✅ **Solved Permission Problem**: Services can securely access AWS resources
✅ **Kubernetes Native**: Uses IRSA for seamless integration
✅ **Production Ready**: Follows AWS security best practices
✅ **Flexible**: Supports various deployment scenarios
✅ **Multi-Service**: Handles Mimir, Loki, Grafana, and Tempo
