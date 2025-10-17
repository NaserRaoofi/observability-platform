# IRSA (IAM Roles for Service Accounts) Mappings

This document details the IAM Roles for Service Accounts (IRSA) mappings used in the observability stack to provide secure, least-privilege access to AWS services.

## Overview

IRSA allows Kubernetes service accounts to assume AWS IAM roles without storing AWS credentials in the cluster. This provides:

- **Security**: No hardcoded AWS credentials
- **Auditability**: All actions traceable to specific service accounts
- **Least Privilege**: Fine-grained permissions per service

## Service Account to IAM Role Mappings

### 1. Loki Service Account

```yaml
ServiceAccount: loki-sa
Namespace: observability
IAM Role: arn:aws:iam::ACCOUNT_ID:role/observability-loki-role
```

**Permissions:**

- S3 bucket access for log storage
- KMS decrypt/encrypt for data encryption
- CloudWatch metrics publishing

**Terraform Configuration:**

```hcl
module "loki_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "observability-loki-role"

  attach_s3_policy = true
  s3_bucket_arns   = [module.loki_bucket.s3_bucket_arn]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["observability:loki-sa"]
    }
  }
}
```

### 2. Mimir Service Account

```yaml
ServiceAccount: mimir-sa
Namespace: observability
IAM Role: arn:aws:iam::ACCOUNT_ID:role/observability-mimir-role
```

**Permissions:**

- S3 bucket access for metrics storage
- DynamoDB access for index tables
- KMS decrypt/encrypt for data encryption

### 3. Tempo Service Account

```yaml
ServiceAccount: tempo-sa
Namespace: observability
IAM Role: arn:aws:iam::ACCOUNT_ID:role/observability-tempo-role
```

**Permissions:**

- S3 bucket access for trace storage
- KMS decrypt/encrypt for data encryption

### 4. Grafana Service Account

```yaml
ServiceAccount: grafana-sa
Namespace: observability
IAM Role: arn:aws:iam::ACCOUNT_ID:role/observability-grafana-role
```

**Permissions:**

- CloudWatch read access for AWS metrics
- Optional: S3 access for dashboard backups

### 5. OTEL Collector Service Account

```yaml
ServiceAccount: otel-collector-sa
Namespace: observability
IAM Role: arn:aws:iam::ACCOUNT_ID:role/observability-otel-role
```

**Permissions:**

- CloudWatch metrics/logs publishing
- X-Ray trace submission

## Detailed Role Policies

### Loki Role Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::observability-loki-*"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::observability-loki-*/*"
    },
    {
      "Effect": "Allow",
      "Action": ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey"],
      "Resource": "arn:aws:kms:*:*:key/OBSERVABILITY_KMS_KEY_ID"
    }
  ]
}
```

### Mimir Role Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::observability-mimir-*"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::observability-mimir-*/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/observability-mimir-*"
    },
    {
      "Effect": "Allow",
      "Action": ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey"],
      "Resource": "arn:aws:kms:*:*:key/OBSERVABILITY_KMS_KEY_ID"
    }
  ]
}
```

## Trust Relationships

All roles use the following trust relationship template:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/EKS_OIDC_PROVIDER"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "EKS_OIDC_PROVIDER:sub": "system:serviceaccount:observability:SERVICE_ACCOUNT_NAME",
          "EKS_OIDC_PROVIDER:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
```

## Implementation Steps

### 1. EKS OIDC Provider Setup

```bash
# The OIDC provider is automatically configured by the EKS module
# Verify it exists:
aws eks describe-cluster --name observability-{environment} --query "cluster.identity.oidc.issuer"
```

### 2. Create IAM Roles

```bash
# Apply Terraform configurations
cd terraform/envs/{environment}
terraform apply
```

### 3. Annotate Service Accounts

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: loki-sa
  namespace: observability
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/observability-loki-role
```

### 4. Configure Pods

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: loki
spec:
  template:
    spec:
      serviceAccountName: loki-sa
      # Pod will automatically assume the IAM role
```

## Validation and Testing

### 1. Verify Role Assumption

```bash
# Exec into pod and check AWS credentials
kubectl exec -it loki-0 -n observability -- aws sts get-caller-identity
```

### 2. Test S3 Access

```bash
# Test S3 access from within pod
kubectl exec -it loki-0 -n observability -- aws s3 ls s3://observability-loki-bucket/
```

### 3. Monitor CloudTrail

- Monitor CloudTrail logs for AssumeRoleWithWebIdentity events
- Verify actions are performed with correct assumed roles

## Security Best Practices

### 1. Principle of Least Privilege

- Grant minimum permissions required
- Use resource-specific ARNs where possible
- Regular permission audits

### 2. Monitoring and Alerting

- CloudTrail logging enabled
- CloudWatch alarms for unusual activity
- Regular access reviews

### 3. Role Rotation

- Periodic review of role permissions
- Update policies based on service changes
- Remove unused roles promptly

## Troubleshooting

### Common Issues

1. **Pod cannot assume role**

   - Check service account annotation
   - Verify OIDC provider configuration
   - Check trust relationship

2. **Access denied errors**

   - Review IAM policy permissions
   - Check resource ARNs
   - Verify condition statements

3. **Token expiration**
   - Check pod security policy
   - Verify token refresh mechanisms
   - Review AWS STS settings

### Debug Commands

```bash
# Check service account
kubectl describe sa loki-sa -n observability

# Check pod annotations
kubectl describe pod loki-0 -n observability

# Check AWS credentials in pod
kubectl exec -it loki-0 -n observability -- env | grep AWS
```
