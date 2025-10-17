# Observability Enterprise Terraform Modules

This directory contains reusable Terraform modules for building a complete observability stack on AWS with security best practices, cost optimization, and enterprise-grade features.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Observability Enterprise Stack               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │   DynamoDB  │  │     IAM     │  │   S3-KMS    │            │
│  │   Module    │  │   Module    │  │   Module    │            │
│  │             │  │             │  │             │            │
│  │ • Mimir     │  │ • IRSA      │  │ • Metrics   │            │
│  │   Tables    │  │   Roles     │  │   Storage   │            │
│  │ • Loki      │  │ • Policies  │  │ • Logs      │            │
│  │   Indexes   │  │ • Service   │  │   Storage   │            │
│  │ • Global    │  │   Accounts  │  │ • Traces    │            │
│  │   Indexes   │  │ • Cross-    │  │   Storage   │            │
│  │             │  │   Service   │  │ • KMS       │            │
│  └─────────────┘  │   Access    │  │   Keys      │            │
│                   └─────────────┘  └─────────────┘            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                          Integration Layer                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Kubernetes Workloads ──► IRSA ──► AWS Services               │
│                                                                 │
│   ┌─────────┐              ┌─────────┐      ┌─────────────┐    │
│   │ Mimir   │─────────────►│DynamoDB │      │     S3      │    │
│   │ Pod     │              │ Tables  │      │   Buckets   │    │
│   └─────────┘              └─────────┘      └─────────────┘    │
│                                                                 │
│   ┌─────────┐              ┌─────────┐      ┌─────────────┐    │
│   │ Loki    │─────────────►│DynamoDB │      │     S3      │    │
│   │ Pod     │              │ Indexes │      │   Buckets   │    │
│   └─────────┘              └─────────┘      └─────────────┘    │
│                                                                 │
│   ┌─────────┐                               ┌─────────────┐    │
│   │ Tempo   │──────────────────────────────►│     S3      │    │
│   │ Pod     │                               │   Buckets   │    │
│   └─────────┘                               └─────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 📦 Available Modules

### [DynamoDB Module](./dynamodb/)

**Purpose**: High-performance NoSQL storage for metrics and log indexing

- ✅ **Mimir Tables** - Metrics metadata and series indexing
- ✅ **Loki Indexes** - Log stream and chunk indexing
- ✅ **Performance Optimized** - GSI configuration for fast queries
- ✅ **Cost Effective** - Pay-per-request billing with burst capacity
- ✅ **Production Ready** - CloudPosse module integration

**Key Features:**

- Conditional table creation for flexible deployments
- Optimized partition/sort key design for time-series data
- Global Secondary Indexes for efficient queries
- Point-in-time recovery and encryption at rest

### [IAM Module](./iam/)

**Purpose**: Secure access management using IRSA (IAM Roles for Service Accounts)

- ✅ **IRSA Pattern** - Kubernetes service account to AWS role mapping
- ✅ **Least Privilege** - Fine-grained permissions per service
- ✅ **Cross-Service Access** - Secure communication between components
- ✅ **Enterprise Security** - Comprehensive policy management

**Key Features:**

- Dedicated roles for Mimir, Loki, Grafana, and Tempo
- Custom policies for DynamoDB and S3 access
- OIDC trust relationships for EKS integration
- Principle of least privilege implementation

### [S3-KMS Module](./s3-kms/)

**Purpose**: Encrypted object storage with intelligent lifecycle management

- ✅ **Customer-Managed KMS** - Full encryption key control
- ✅ **Service-Specific Buckets** - Optimized for each workload
- ✅ **Lifecycle Management** - Automatic cost optimization
- ✅ **Security Hardened** - Public access blocked, SSL-only

**Key Features:**

- Separate buckets for metrics, logs, and traces
- Intelligent tiering and lifecycle transitions
- Cross-origin resource sharing (CORS) for web interfaces
- Comprehensive monitoring and notifications

## 🚀 Quick Start

### Complete Stack Deployment

```hcl
# terraform/envs/prod/main.tf
module "observability_dynamodb" {
  source = "../../modules/dynamodb"

  environment         = "prod"
  create_mimir_tables = true
  create_loki_tables  = true
}

module "observability_s3" {
  source = "../../modules/s3-kms"

  environment         = "prod"
  project_name        = "observability"
  create_mimir_bucket = true
  create_loki_bucket  = true
  create_tempo_bucket = true
  create_kms_key      = true
}

module "observability_iam" {
  source = "../../modules/iam"

  cluster_name        = "prod-eks"
  environment         = "prod"

  # Integration with other modules
  mimir_dynamodb_table_arn = module.observability_dynamodb.mimir_table_arn
  loki_dynamodb_table_arn  = module.observability_dynamodb.loki_table_arn
  mimir_s3_bucket_arn      = module.observability_s3.mimir_bucket_arn
  loki_s3_bucket_arn       = module.observability_s3.loki_bucket_arn
  tempo_s3_bucket_arn      = module.observability_s3.tempo_bucket_arn
}
```

### Service-Specific Deployment

```hcl
# Deploy only Mimir components
module "mimir_only" {
  source = "../../modules/dynamodb"

  create_mimir_tables = true
  create_loki_tables  = false
}

module "mimir_storage" {
  source = "../../modules/s3-kms"

  create_mimir_bucket = true
  create_loki_bucket  = false
  create_tempo_bucket = false
}
```

## 🔧 Module Integration

### Data Flow

1. **DynamoDB Module** creates tables for metadata storage
2. **S3-KMS Module** creates encrypted buckets for data storage
3. **IAM Module** creates roles referencing the above resources
4. **Kubernetes Pods** assume roles via IRSA for secure access

### Cross-Module References

```hcl
# IAM module references DynamoDB and S3 resources
module "iam" {
  mimir_dynamodb_table_arn = module.dynamodb.mimir_table_arn
  mimir_s3_bucket_arn      = module.s3.mimir_bucket_arn
  # ... other references
}
```

## 🏢 Enterprise Features

### Security

- **Encryption at Rest** - KMS customer-managed keys
- **Encryption in Transit** - SSL/TLS enforcement
- **Access Control** - IRSA with least privilege
- **Audit Logging** - Comprehensive access logs

### Cost Optimization

- **Intelligent Tiering** - Automatic storage class transitions
- **Lifecycle Policies** - Automated data archival and deletion
- **Pay-per-Request** - DynamoDB billing optimization
- **Resource Tagging** - Cost allocation and tracking

### Operations

- **Monitoring Integration** - CloudWatch metrics and alarms
- **Notification System** - SNS integration for operational events
- **Backup and Recovery** - Point-in-time recovery for DynamoDB
- **Multi-Environment** - Support for dev, staging, prod deployments

## 📋 Requirements

### Terraform

- **Version**: >= 1.0
- **Providers**: AWS >= 5.0

### AWS Prerequisites

- EKS cluster with OIDC provider enabled
- VPC with private subnets
- Appropriate IAM permissions for Terraform

### Dependencies

The following remote modules are cloned at the project root:

- `terraform-aws-dynamodb/` (CloudPosse)
- `terraform-aws-iam/` (terraform-aws-modules)
- `terraform-aws-s3-bucket/` (terraform-aws-modules)

## 🧪 Testing

### Unit Testing

```bash
# Test individual modules
cd terraform/modules/dynamodb && terraform plan
cd terraform/modules/iam && terraform plan
cd terraform/modules/s3-kms && terraform plan
```

### Integration Testing

```bash
# Test complete stack
cd terraform/envs/dev && terraform plan
```

### Validation

```bash
# Validate Terraform syntax
terraform fmt -recursive
terraform validate
```

## 📚 Documentation

### Module-Specific Docs

- [DynamoDB Module README](./dynamodb/README.md)
- [IAM Module README](./iam/README.md)
- [S3-KMS Module README](./s3-kms/README.md)

### Usage Examples

- [DynamoDB Examples](./dynamodb/USAGE_EXAMPLES.md)
- [IAM Examples](./iam/USAGE_EXAMPLES.md)
- [S3-KMS Examples](./s3-kms/USAGE_EXAMPLES.md)

## 🤝 Contributing

1. **Follow Module Standards** - Consistent variable naming and structure
2. **Update Documentation** - README and examples for any changes
3. **Test Changes** - Validate in dev environment before production
4. **Security Review** - Ensure least privilege and encryption standards

## 📊 Cost Estimation

### Development Environment

- **DynamoDB**: $5-15/month (low traffic)
- **S3**: $5-20/month (small data sets)
- **Total**: ~$10-35/month

### Production Environment

- **DynamoDB**: $50-200/month (moderate traffic)
- **S3**: $100-500/month (depends on retention)
- **Total**: ~$150-700/month

_Costs vary significantly based on data volume, retention policies, and access patterns._

## 🆘 Support

### Common Issues

1. **IRSA Trust Relationship** - Ensure EKS OIDC provider is correctly configured
2. **S3 Bucket Naming** - Bucket names must be globally unique
3. **DynamoDB Capacity** - Monitor for throttling in high-traffic scenarios

### Troubleshooting

- Check AWS CloudTrail for access issues
- Review IAM policy simulator for permission problems
- Monitor CloudWatch metrics for performance issues

---

This modular approach provides a complete, enterprise-ready observability infrastructure that scales with your organization's needs while maintaining security and cost optimization best practices.
