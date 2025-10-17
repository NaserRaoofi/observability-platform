# IAM Module Usage Examples for Observability Stack

## Overview

This module creates IAM roles and policies for the observability stack components (Mimir, Loki, Grafana) to access AWS services like DynamoDB and S3 through IRSA (IAM Roles for Service Accounts).

## Prerequisites

- EKS cluster with OIDC provider configured
- DynamoDB tables created (from our DynamoDB module)
- S3 buckets created (from S3 module)

## Basic Usage - Mimir Only

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

## Full Observability Stack

```hcl
module "observability_iam" {
  source = "./modules/iam"

  # Environment configuration
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

  # Enable all services
  create_loki_resources    = true
  create_grafana_resources = true

  # Additional policies if needed
  mimir_additional_policies = {
    CustomMetricsPolicy = aws_iam_policy.custom_metrics.arn
  }

  tags = {
    Environment = "prod"
    Team        = "platform"
    CostCenter  = "engineering"
  }
}
```

## Multi-Cluster Setup

```hcl
module "observability_iam" {
  source = "./modules/iam"

  environment  = "prod"
  project_name = "observability"

  # Primary EKS cluster
  eks_oidc_provider_arn = module.eks_primary.oidc_provider_arn
  monitoring_namespace  = "monitoring"

  # Additional OIDC providers for multi-cluster
  additional_oidc_providers = {
    secondary = {
      provider_arn = module.eks_secondary.oidc_provider_arn
      namespace_service_accounts = [
        "monitoring:mimir",
        "monitoring:loki",
        "monitoring:grafana"
      ]
    }
    dr_cluster = {
      provider_arn = module.eks_dr.oidc_provider_arn
      namespace_service_accounts = [
        "monitoring:mimir",
        "monitoring:grafana"
      ]
    }
  }

  # Resource ARNs
  mimir_table_arn     = module.observability_dynamodb.mimir_table_arn
  loki_table_arn      = module.observability_dynamodb.loki_table_arn
  mimir_s3_bucket_arn = module.observability_s3.mimir_bucket_arn
  loki_s3_bucket_arn  = module.observability_s3.loki_bucket_arn

  create_loki_resources    = true
  create_grafana_resources = true
}
```

## Cross-Account Access

```hcl
module "observability_iam" {
  source = "./modules/iam"

  environment  = "prod"
  project_name = "observability"

  eks_oidc_provider_arn = module.eks.oidc_provider_arn
  monitoring_namespace  = "monitoring"

  # Cross-account configuration
  enable_cross_account_access = true
  trusted_account_ids         = ["123456789012", "210987654321"]

  # Resource ARNs
  mimir_table_arn     = module.observability_dynamodb.mimir_table_arn
  mimir_s3_bucket_arn = module.observability_s3.mimir_bucket_arn

  create_loki_resources    = false
  create_grafana_resources = true
}
```

## Kubernetes Service Account Configuration

After applying the IAM module, you need to configure your Kubernetes service accounts with the proper annotations:

### Mimir Service Account

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: mimir
  namespace: monitoring
  annotations:
    eks.amazonaws.com/role-arn: "${module.observability_iam.mimir_role_arn}"
automountServiceAccountToken: true
```

### Loki Service Account (if enabled)

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: loki
  namespace: monitoring
  annotations:
    eks.amazonaws.com/role-arn: "${module.observability_iam.loki_role_arn}"
automountServiceAccountToken: true
```

### Grafana Service Account (if enabled)

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: grafana
  namespace: monitoring
  annotations:
    eks.amazonaws.com/role-arn: "${module.observability_iam.grafana_role_arn}"
automountServiceAccountToken: true
```

## Using Outputs for Helm Charts

### Mimir Helm Values

```yaml
# values-mimir.yaml
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

### Loki Helm Values

```yaml
# values-loki.yaml
serviceAccount:
  create: true
  name: loki
  annotations:
    eks.amazonaws.com/role-arn: "${module.observability_iam.loki_role_arn}"

storage:
  dynamodb:
    table_name: "${module.observability_dynamodb.loki_table_name}"
  s3:
    bucket: "${module.observability_s3.loki_bucket_name}"
```

### Grafana Helm Values

```yaml
# values-grafana.yaml
serviceAccount:
  create: true
  name: grafana
  annotations:
    eks.amazonaws.com/role-arn: "${module.observability_iam.grafana_role_arn}"

datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
      - name: Prometheus
        type: prometheus
        url: http://mimir-query-frontend:8080/prometheus
        access: proxy
        isDefault: true
```

## IAM Permissions Summary

### Mimir Permissions

- **DynamoDB**: Full read/write access to metrics table and indexes
- **S3**: Full read/write access to metrics storage bucket
- **CloudWatch**: Metrics publishing permissions

### Loki Permissions

- **DynamoDB**: Full read/write access to logs index table
- **S3**: Full read/write access to logs storage bucket
- **CloudWatch**: Logs publishing permissions

### Grafana Permissions

- **CloudWatch**: Read-only access to metrics and logs
- **Prometheus/AMP**: Read-only access to managed Prometheus
- **EC2/EKS**: Resource discovery for dynamic dashboards

## Security Best Practices

1. **Principle of Least Privilege**: Each service only gets the minimum required permissions
2. **Resource-Specific Access**: Policies are scoped to specific tables/buckets
3. **Namespace Isolation**: Service accounts are tied to specific Kubernetes namespaces
4. **Cross-Account Controls**: Optional cross-account access with explicit trust relationships

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

# Check AWS credentials in pod
kubectl exec -it <mimir-pod> -n monitoring -- env | grep AWS

# Test AWS API access
kubectl exec -it <mimir-pod> -n monitoring -- aws sts get-caller-identity
```
