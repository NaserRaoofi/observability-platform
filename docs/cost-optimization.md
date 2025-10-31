# Cost Optimization Guide

This document provides strategies and best practices to optimize costs for the observability platform while maintaining functionality and reliability.

## 🎯 **Cost Optimization Strategy**

### **1. Development Environment Settings**

The dev environment is configured with cost-effective settings:

#### **DynamoDB Optimizations**

- **Billing Mode**: `PAY_PER_REQUEST` instead of provisioned capacity
- **Backup**: Point-in-time recovery disabled in dev
- **Retention**: Shorter retention periods for dev data

#### **S3 Optimizations**

- **Storage Classes**: Intelligent Tiering enabled for automatic cost optimization
- **Lifecycle Rules**: Automated transition to cheaper storage classes
- **Encryption**: KMS key rotation disabled in dev to reduce costs

#### **EKS/Kubernetes Optimizations**

- **Node Types**: Use spot instances for non-critical workloads
- **Scaling**: Cluster autoscaler for right-sizing
- **Resource Limits**: Proper resource requests/limits to avoid over-provisioning

### **2. Data Retention Policies**

```yaml
# Recommended retention settings by environment
Development:
  Metrics: 7 days
  Logs: 3 days
  Traces: 1 day

Staging:
  Metrics: 30 days
  Logs: 14 days
  Traces: 7 days

Production:
  Metrics: 90 days
  Logs: 30 days
  Traces: 14 days
```

### **3. Sampling Strategies**

#### **Trace Sampling**

- **Head-based sampling**: 1% for high-volume services
- **Tail-based sampling**: Keep error traces, sample successful ones
- **Probabilistic sampling**: Adjust based on traffic volume

#### **Metrics Sampling**

- **High-cardinality metrics**: Careful labeling to avoid explosion
- **Recording rules**: Pre-aggregate expensive queries
- **Metric relabeling**: Drop unnecessary labels

### **4. Infrastructure Right-Sizing**

#### **Mimir Components**

```yaml
# Cost-optimized resource allocation
mimir:
  ingester:
    resources:
      requests: { cpu: 100m, memory: 512Mi }
      limits: { cpu: 500m, memory: 1Gi }

  querier:
    resources:
      requests: { cpu: 50m, memory: 256Mi }
      limits: { cpu: 200m, memory: 512Mi }
```

#### **Loki Components**

```yaml
loki:
  write:
    resources:
      requests: { cpu: 50m, memory: 256Mi }
      limits: { cpu: 200m, memory: 512Mi }

  read:
    resources:
      requests: { cpu: 50m, memory: 256Mi }
      limits: { cpu: 200m, memory: 512Mi }
```

### **5. AWS Cost Management**

#### **Reserved Instances**

- Use RIs for predictable workloads in production
- Consider Savings Plans for flexible usage patterns

#### **Spot Instances**

- Use for development and testing environments
- Implement graceful handling of spot interruptions

#### **Data Transfer Optimization**

- Keep components in same AZ when possible
- Use VPC endpoints for S3 access
- Compress data before storage

### **6. Monitoring Cost Metrics**

Create alerts for:

- DynamoDB consumption units
- S3 storage growth rate
- CloudWatch API calls
- Data transfer costs
- EKS compute costs

### **7. Feature Flags for Cost Control**

Use feature flags to disable expensive features in dev:

```terraform
# Development cost controls
variable "create_loki_resources" {
  description = "Enable Loki (logs) - disable in dev if not needed"
  type        = bool
  default     = false  # Disabled by default in dev
}

variable "create_tempo_resources" {
  description = "Enable Tempo (traces) - disable in dev if not needed"
  type        = bool
  default     = false  # Disabled by default in dev
}

variable "enable_high_availability" {
  description = "Enable HA deployment - disable in dev"
  type        = bool
  default     = false  # Single instance in dev
}
```

### **8. Regular Cost Reviews**

#### **Weekly Reviews**

- Check AWS Cost Explorer for spending trends
- Review DynamoDB consumption metrics
- Monitor S3 storage growth

#### **Monthly Optimization**

- Analyze unused resources
- Review retention policies
- Update resource allocations based on usage

#### **Quarterly Planning**

- Evaluate Reserved Instance renewals
- Update cost forecasts
- Plan for capacity changes

## 💰 **Estimated Cost Savings**

With these optimizations, expect:

- **Development**: 70-80% cost reduction vs production
- **Staging**: 40-50% cost reduction vs production
- **Production**: 20-30% optimization through right-sizing

## 🚨 **Cost Alerts Setup**

```terraform
# Example CloudWatch billing alerts
resource "aws_cloudwatch_metric_alarm" "billing_alert" {
  alarm_name          = "observability-billing-alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "86400"  # 24 hours
  statistic           = "Maximum"
  threshold           = "100"    # $100 threshold
  alarm_description   = "This metric monitors estimated billing charges"
  alarm_actions       = [aws_sns_topic.billing_alerts.arn]

  dimensions = {
    Currency = "USD"
  }
}
```
