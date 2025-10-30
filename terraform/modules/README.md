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

### Production Environment Example

```hcl
# terraform/envs/prod/main.tf

locals {
  environment = "prod"
  project     = "observability"

  common_tags = {
    Environment = local.environment
    Project     = local.project
    ManagedBy   = "terraform"
    Owner       = "platform-team"
  }
}

# DynamoDB Module - Tables for Indexing
module "observability_dynamodb" {
  source = "../../modules/dynamodb"

  environment  = local.environment
  project_name = local.project

  # Enable tables for services we're deploying
  create_mimir_table = true
  create_loki_table  = true

  # Performance configuration
  billing_mode = "PAY_PER_REQUEST"  # Cost-effective for variable workloads

  # Security
  point_in_time_recovery_enabled = true

  tags = local.common_tags
}

# S3-KMS Module - Storage with Encryption
module "observability_s3" {
  source = "../../modules/s3-kms"

  environment  = local.environment
  project_name = local.project

  # Enable buckets for services we're deploying
  create_mimir_bucket = true
  create_loki_bucket  = true
  create_tempo_bucket = true

  # KMS encryption
  create_kms_key      = true
  enable_key_rotation = true

  # Lifecycle management for cost optimization
  enable_lifecycle_management = true
  logs_retention_days         = 365   # 1 year for logs
  traces_retention_days       = 90    # 90 days for traces

  # Performance optimizations
  enable_transfer_acceleration = true
  enable_intelligent_tiering   = true

  tags = local.common_tags
}

# IAM Module - IRSA Roles and Policies
module "observability_iam" {
  source = "../../modules/iam"

  environment  = local.environment
  project_name = local.project

  # EKS cluster configuration
  eks_oidc_provider_arn = var.eks_oidc_provider_arn
  monitoring_namespace  = "monitoring"

  # Cross-module resource references
  mimir_table_arn     = module.observability_dynamodb.mimir_table_arn
  loki_table_arn      = module.observability_dynamodb.loki_table_arn
  mimir_s3_bucket_arn = module.observability_s3.mimir_bucket_arn
  loki_s3_bucket_arn  = module.observability_s3.loki_bucket_arn
  tempo_s3_bucket_arn = module.observability_s3.tempo_bucket_arn

  # KMS key for encryption/decryption
  kms_key_arn = module.observability_s3.kms_key_arn

  # Feature flags
  create_loki_resources    = true
  create_grafana_resources = true
  create_tempo_resources   = true

  tags = local.common_tags
}

# Integration summary for easy reference
output "observability_stack_summary" {
  description = "Complete observability stack configuration summary"
  value = {
    environment = local.environment

    # Storage layer
    storage = {
      mimir_dynamodb_table = module.observability_dynamodb.mimir_table_name
      mimir_s3_bucket     = module.observability_s3.mimir_bucket_name
      loki_dynamodb_table = module.observability_dynamodb.loki_table_name
      loki_s3_bucket      = module.observability_s3.loki_bucket_name
      tempo_s3_bucket     = module.observability_s3.tempo_bucket_name
      kms_key_id          = module.observability_s3.kms_key_id
    }

    # Security layer
    security = {
      mimir_service_account_role   = module.observability_iam.mimir_role_arn
      loki_service_account_role    = module.observability_iam.loki_role_arn
      grafana_service_account_role = module.observability_iam.grafana_role_arn
      tempo_service_account_role   = module.observability_iam.tempo_role_arn
    }

    # Configuration for Kubernetes deployments
    kubernetes_annotations = {
      mimir_service_account   = "eks.amazonaws.com/role-arn: ${module.observability_iam.mimir_role_arn}"
      loki_service_account    = "eks.amazonaws.com/role-arn: ${module.observability_iam.loki_role_arn}"
      grafana_service_account = "eks.amazonaws.com/role-arn: ${module.observability_iam.grafana_role_arn}"
      tempo_service_account   = "eks.amazonaws.com/role-arn: ${module.observability_iam.tempo_role_arn}"
    }
  }
}
```

### Service-Specific Deployment

```hcl
# Deploy only Mimir components
module "mimir_only" {
  source = "../../modules/dynamodb"

  create_mimir_table = true
  create_loki_table  = false
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
  mimir_table_arn     = module.dynamodb.mimir_table_arn
  mimir_s3_bucket_arn = module.s3.mimir_bucket_arn
  # ... other references
}
```

## 🚀 Kubernetes Integration

### Service Account Configuration

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
# Tempo Service Account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tempo
  namespace: monitoring
  annotations:
    eks.amazonaws.com/role-arn: "${module.observability_iam.tempo_role_arn}"
automountServiceAccountToken: true
```

### Mimir Helm Configuration

```yaml
# Use the Terraform outputs in your Helm values
mimir:
  storage:
    backend: s3
    s3:
      bucket_name: "observability-prod-mimir"
      region: "us-west-2"

  indexGateway:
    storage:
      type: dynamodb
      dynamodb:
        table_name: "observability-prod-mimir"
        region: "us-west-2"

  serviceAccount:
    create: false
    name: mimir
```

### Loki Helm Configuration

```yaml
storage_config:
  aws:
    bucketnames: "${module.observability_s3.loki_bucket_name}"
    region: "${data.aws_region.current.name}"
    sse_encryption: true

serviceAccount:
  create: false
  name: loki
```

## 📋 Deployment Steps

### 1. Initialize Terraform

```bash
cd terraform/envs/prod
terraform init
```

### 2. Plan Deployment

```bash
terraform plan -var-file="terraform.tfvars"
```

### 3. Deploy Infrastructure

```bash
terraform apply -var-file="terraform.tfvars"
```

### 4. Verify Resources

```bash
# Check DynamoDB tables
aws dynamodb list-tables --region us-west-2

# Check S3 buckets
aws s3 ls | grep observability

# Check IAM roles
aws iam list-roles --query 'Roles[?contains(RoleName, `observability`)]'
```

### 5. Deploy Kubernetes Applications

```bash
# Apply service accounts
kubectl apply -f k8s/service-accounts.yaml

# Deploy via Helm
helm upgrade --install mimir grafana/mimir-distributed -f values-mimir.yaml
helm upgrade --install loki grafana/loki -f values-loki.yaml
helm upgrade --install tempo grafana/tempo -f values-tempo.yaml
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

## 🛠️ Troubleshooting

### Common Issues

1. **IRSA Trust Relationship Errors**

   ```bash
   # Verify OIDC provider exists
   aws iam list-open-id-connect-providers

   # Check trust policy
   aws iam get-role --role-name observability-prod-mimir-role
   ```

2. **S3 Access Denied**

   ```bash
   # Test bucket access
   aws s3 ls s3://observability-prod-mimir --region us-west-2

   # Check bucket policy
   aws s3api get-bucket-policy --bucket observability-prod-mimir
   ```

3. **DynamoDB Throttling**
   ```bash
   # Check table metrics
   aws cloudwatch get-metric-statistics \
     --namespace AWS/DynamoDB \
     --metric-name ThrottledRequests \
     --dimensions Name=TableName,Value=observability-prod-mimir \
     --start-time 2024-01-01T00:00:00Z \
     --end-time 2024-01-02T00:00:00Z \
     --period 3600 \
     --statistics Sum
   ```

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

## 💰 Cost Optimization

### Expected Monthly Costs (Production)

- **DynamoDB**: $50-200 (depends on read/write patterns)
- **S3 Storage**: $100-500 (depends on data volume and lifecycle)
- **KMS**: $1-5 (key usage)
- **Data Transfer**: $10-100 (depends on cross-AZ traffic)

**Total**: ~$160-800/month for production workload

### Cost Reduction Strategies

1. **Lifecycle Policies**: Automatic transition to cheaper storage classes
2. **Intelligent Tiering**: S3 automatically optimizes storage costs
3. **Pay-per-Request**: DynamoDB billing only for actual usage
4. **Retention Policies**: Automatic cleanup of old data
5. **Resource Tagging**: Detailed cost allocation and tracking

## 🔐 Security Considerations

### Encryption

- ✅ **DynamoDB**: Encryption at rest with AWS managed keys
- ✅ **S3**: Customer-managed KMS keys with rotation
- ✅ **Transit**: All connections use TLS 1.2+

### Access Control

- ✅ **Least Privilege**: Each service has minimal required permissions
- ✅ **IRSA**: Secure token exchange without long-lived credentials
- ✅ **Resource-Based**: Bucket policies restrict access to specific roles

### Monitoring

- ✅ **CloudTrail**: All API calls logged
- ✅ **Access Logs**: S3 bucket access logging enabled
- ✅ **Metrics**: CloudWatch metrics for all services

## 🆘 Support

---

This modular approach provides a complete, enterprise-ready observability infrastructure that scales with your organization's needs while maintaining security and cost optimization best practices.
