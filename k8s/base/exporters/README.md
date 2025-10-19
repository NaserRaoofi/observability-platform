# Exporters - Professional Helm Chart Configuration

This directory contains configurations for official Helm charts to deploy Prometheus exporters in our observability stack.

## Official Charts Used

### Prometheus Community Charts

```bash
# Add the prometheus-community repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

## Available Exporters

### 1. Node Exporter

- **Chart**: `prometheus-community/prometheus-node-exporter`
- **Purpose**: Hardware and OS metrics from Kubernetes nodes
- **Files**:
  - `node-exporter/values.yaml` - Base configuration
  - `node-exporter/values-dev.yaml` - Development overrides
  - `node-exporter/values-prod.yaml` - Production overrides

### 2. Kube State Metrics

- **Chart**: `prometheus-community/kube-state-metrics`
- **Purpose**: Kubernetes API object metrics
- **Files**:
  - `kube-state-metrics/values.yaml` - Base configuration
  - `kube-state-metrics/values-dev.yaml` - Development overrides
  - `kube-state-metrics/values-prod.yaml` - Production overrides

### 3. Blackbox Exporter

- **Chart**: `prometheus-community/prometheus-blackbox-exporter`
- **Purpose**: Synthetic monitoring and health checks
- **Files**:
  - `blackbox-exporter/values.yaml` - Base configuration

### 4. Nginx Exporter

- **Chart**: `prometheus-community/prometheus-nginx-exporter`
- **Purpose**: Nginx web server metrics and performance monitoring
- **Files**:
  - `nginx-exporter/values.yaml` - Base configuration

### 5. Redis Exporter

- **Chart**: `prometheus-community/prometheus-redis-exporter`
- **Purpose**: Redis database performance, memory, and connection metrics
- **Files**:
  - `redis-exporter/values.yaml` - Base configuration

### 6. AWS CloudWatch Exporter

- **Chart**: `prometheus-community/prometheus-cloudwatch-exporter`
- **Purpose**: AWS service metrics and CloudWatch integration with IRSA support
- **Files**:
  - `aws-cloudwatch-exporter/values.yaml` - Base configuration

## Deployment Commands

### Development Environment

```bash
# Node Exporter
helm upgrade --install node-exporter prometheus-community/prometheus-node-exporter \
  --namespace monitoring --create-namespace \
  -f exporters/node-exporter/values.yaml \
  -f exporters/node-exporter/values-dev.yaml

# Kube State Metrics
helm upgrade --install kube-state-metrics prometheus-community/kube-state-metrics \
  --namespace monitoring \
  -f exporters/kube-state-metrics/values.yaml \
  -f exporters/kube-state-metrics/values-dev.yaml

# Blackbox Exporter
helm upgrade --install blackbox-exporter prometheus-community/prometheus-blackbox-exporter \
  --namespace monitoring \
  -f exporters/blackbox-exporter/values.yaml

# Nginx Exporter
helm upgrade --install nginx-exporter prometheus-community/prometheus-nginx-exporter \
  --namespace monitoring \
  -f exporters/nginx-exporter/values.yaml

# Redis Exporter
helm upgrade --install redis-exporter prometheus-community/prometheus-redis-exporter \
  --namespace monitoring \
  -f exporters/redis-exporter/values.yaml

# AWS CloudWatch Exporter
helm upgrade --install aws-cloudwatch-exporter prometheus-community/prometheus-cloudwatch-exporter \
  --namespace monitoring \
  -f exporters/aws-cloudwatch-exporter/values.yaml
```

### Production Environment

```bash
# Node Exporter
helm upgrade --install node-exporter prometheus-community/prometheus-node-exporter \
  --namespace monitoring --create-namespace \
  -f exporters/node-exporter/values.yaml \
  -f exporters/node-exporter/values-prod.yaml

# Kube State Metrics
helm upgrade --install kube-state-metrics prometheus-community/kube-state-metrics \
  --namespace monitoring \
  -f exporters/kube-state-metrics/values.yaml \
  -f exporters/kube-state-metrics/values-prod.yaml

# Blackbox Exporter
helm upgrade --install blackbox-exporter prometheus-community/prometheus-blackbox-exporter \
  --namespace monitoring \
  -f exporters/blackbox-exporter/values.yaml

# Nginx Exporter
helm upgrade --install nginx-exporter prometheus-community/prometheus-nginx-exporter \
  --namespace monitoring \
  -f exporters/nginx-exporter/values.yaml

# Redis Exporter
helm upgrade --install redis-exporter prometheus-community/prometheus-redis-exporter \
  --namespace monitoring \
  -f exporters/redis-exporter/values.yaml

# AWS CloudWatch Exporter
helm upgrade --install aws-cloudwatch-exporter prometheus-community/prometheus-cloudwatch-exporter \
  --namespace monitoring \
  -f exporters/aws-cloudwatch-exporter/values.yaml
```

## IRSA Integration

**AWS CloudWatch Exporter** requires IRSA for CloudWatch API access:

```yaml
# AWS CloudWatch Exporter service account annotation
serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: ${cloudwatch_exporter_irsa_role_arn}
```

**Other exporters** (Node, Kube State Metrics, Blackbox, Nginx, Redis) do not require IRSA as they monitor local services or perform synthetic checks without AWS API access.

## Monitoring Integration

All exporters include ServiceMonitor configurations for automatic Prometheus discovery:

```yaml
prometheus:
  monitor:
    enabled: true
    additionalLabels:
      app.kubernetes.io/part-of: observability-stack
```

## Repository Management

```bash
# Initial setup
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Periodic updates
helm repo update prometheus-community
```
