# Development Environment

This directory contains Terraform configuration for deploying the observability stack in a development environment with cost optimizations.

## 🏗️ Architecture

The development environment deploys a complete observability stack with the following components:

```
┌─────────────────────────────────────────────────────────────┐
│                 Development Environment                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  EKS Cluster (dev-observability-cluster)                   │
│  ┌─────────────┐               ┌─────────────────────────┐  │
│  │             │     IRSA      │     AWS Services        │  │
│  │ ┌─────────┐ │ ◄────────────► │                        │  │
│  │ │ Mimir   │ │               │ ┌─────────────────────┐ │  │
│  │ │ Pod     │ │               │ │   DynamoDB Tables   │ │  │
│  │ └─────────┘ │               │ │                     │ │  │
│  │             │               │ │ • mimir-dev (✅)    │ │  │
│  │ ┌─────────┐ │               │ │ • loki-dev (✅)     │ │  │
│  │ │ Loki    │ │               │ └─────────────────────┘ │  │
│  │ │ Pod     │ │               │                         │  │
│  │ └─────────┘ │               │ ┌─────────────────────┐ │  │
│  │             │               │ │   S3 Buckets        │ │  │
│  │ ┌─────────┐ │               │ │   + KMS Key         │ │  │
│  │ │Grafana  │ │               │ │                     │ │  │
│  │ │Dashboard│ │               │ │ • mimir-dev (✅)    │ │  │
│  │ └─────────┘ │               │ │ • loki-dev (✅)     │ │  │
│  │             │               │ │ • tempo-dev (❌)    │ │  │
│  └─────────────┘               │ └─────────────────────┘ │  │
│                                 │                         │  │
│                                 │ ┌─────────────────────┐ │  │
│                                 │ │  IAM Roles (IRSA)   │ │  │
│                                 │ │                     │ │  │
│                                 │ │ • mimir-role (✅)   │ │  │
│                                 │ │ • loki-role (✅)    │ │  │
│                                 │ │ • grafana-role (✅) │ │  │
│                                 │ │ • tempo-role (❌)   │ │  │
│                                 │ └─────────────────────┘ │  │
│                                 │                         │  │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

1. **EKS Cluster**: You need an existing EKS cluster with OIDC provider enabled
2. **AWS CLI**: Configured with appropriate permissions
3. **Terraform**: Version >= 1.0 installed

### 1. Configure Variables

Edit `terraform.tfvars` and update these required values:

```hcl
# Update with your actual EKS cluster details
eks_cluster_name      = "your-dev-cluster-name"
eks_oidc_provider_arn = "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/YOUR_OIDC_ID"
```

To find your OIDC provider ARN:

```bash
aws iam list-open-id-connect-providers
```

### 2. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the planned changes
terraform plan -var-file="terraform.tfvars"

# Deploy the infrastructure
terraform apply -var-file="terraform.tfvars"
```

### 3. Configure Kubernetes Service Accounts

After deployment, create service accounts in your Kubernetes cluster:

```yaml
# Create monitoring namespace
kubectl create namespace monitoring

# Create Mimir service account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: mimir
  namespace: monitoring
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::ACCOUNT_ID:role/observability-dev-mimir-role"
---
# Create Loki service account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: loki
  namespace: monitoring
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::ACCOUNT_ID:role/observability-dev-loki-role"
---
# Create Grafana service account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: grafana
  namespace: monitoring
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::ACCOUNT_ID:role/observability-dev-grafana-role"
```

## 📊 Development Configuration

### Cost Optimization Features

- **Pay-per-Request DynamoDB**: No provisioned capacity charges
- **Short Data Retention**:
  - Metrics: 30 days
  - Logs: 7 days
  - Traces: Disabled by default
- **Minimal Monitoring**: CloudWatch metrics disabled to save costs
- **No Point-in-Time Recovery**: Disabled for DynamoDB to reduce costs

### Enabled Services

| Service | DynamoDB Table | S3 Bucket   | IAM Role    | Status       |
| ------- | -------------- | ----------- | ----------- | ------------ |
| Mimir   | ✅ Created     | ✅ Created  | ✅ Created  | **Enabled**  |
| Loki    | ✅ Created     | ✅ Created  | ✅ Created  | **Enabled**  |
| Grafana | ❌ N/A         | ❌ N/A      | ✅ Created  | **Enabled**  |
| Tempo   | ❌ Disabled    | ❌ Disabled | ❌ Disabled | **Disabled** |

### Resource Naming Convention

All resources follow the pattern: `{project}-{environment}-{service}-{resource_type}`

Examples:

- DynamoDB: `observability-dev-mimir`
- S3 Bucket: `observability-dev-mimir-bucket`
- IAM Role: `observability-dev-mimir-role`

## 🔧 Customization

### Enable Additional Services

To enable Tempo for trace development:

```hcl
# In terraform.tfvars
create_tempo_bucket = true
create_tempo_role   = true
```

### Adjust Cost Settings

Modify retention and features in `terraform.tfvars`:

```hcl
# Enable more features (increases costs)
create_kms_key = false  # Disable encryption to save costs
```

## 📋 Outputs

After deployment, Terraform provides comprehensive outputs:

```bash
# View all outputs
terraform output

# View specific output
terraform output dev_observability_summary
```

Key outputs include:

- **DynamoDB table names and ARNs**
- **S3 bucket names and ARNs**
- **IAM role ARNs for service account annotations**
- **KMS key information**
- **Service account configuration examples**

## 🧪 Testing

### Verify Resources

```bash
# Check DynamoDB tables
aws dynamodb list-tables --region us-west-2 | grep observability-dev

# Check S3 buckets
aws s3 ls | grep observability-dev

# Check IAM roles
aws iam list-roles --query 'Roles[?contains(RoleName, `observability-dev`)]'
```

### Test IRSA Integration

```bash
# Deploy a test pod with Mimir service account
kubectl run test-mimir \
  --image=amazon/aws-cli:latest \
  --serviceaccount=mimir \
  --namespace=monitoring \
  --command -- sleep 3600

# Verify AWS access
kubectl exec -n monitoring test-mimir -- aws sts get-caller-identity
```

## 💰 Cost Estimation

### Monthly Costs (Development)

- **DynamoDB**: $5-15/month (pay-per-request with low usage)
- **S3**: $5-20/month (small datasets with lifecycle management)
- **KMS**: $1/month (key usage)
- **Data Transfer**: $1-5/month (minimal cross-AZ traffic)

**Total Estimated Cost**: ~$10-40/month

### Cost Monitoring

```bash
# Check DynamoDB usage
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ConsumedReadCapacityUnits \
  --dimensions Name=TableName,Value=observability-dev-mimir \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Sum

# Check S3 storage usage
aws cloudwatch get-metric-statistics \
  --namespace AWS/S3 \
  --metric-name BucketSizeBytes \
  --dimensions Name=BucketName,Value=observability-dev-mimir-bucket \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 86400 \
  --statistics Average
```

## 🔄 Cleanup

To destroy the development environment:

```bash
# Destroy infrastructure (be careful!)
terraform destroy -var-file="terraform.tfvars"

# Clean up Kubernetes resources
kubectl delete namespace monitoring logging tracing
```

## 🆘 Troubleshooting

### Common Issues

1. **IRSA Trust Relationship Error**

   ```bash
   # Verify OIDC provider exists
   aws iam list-open-id-connect-providers
   ```

2. **S3 Bucket Name Conflicts**

   - S3 bucket names must be globally unique
   - Modify `project_name` in `terraform.tfvars` if needed

3. **DynamoDB Access Denied**
   ```bash
   # Check IAM policies
   aws iam get-role-policy --role-name observability-dev-mimir-role --policy-name MimirDynamoDBPolicy
   ```

### Getting Help

- Check Terraform outputs: `terraform output dev_observability_summary`
- Review AWS CloudTrail logs for access issues
- Validate IAM policies in AWS Console

---

This development environment provides a cost-effective way to develop and test your observability stack while maintaining security and following best practices.
