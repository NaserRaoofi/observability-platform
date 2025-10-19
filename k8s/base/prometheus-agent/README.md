# Prometheus Agent - Metrics Collection & Remote Write

This directory contains the Prometheus Agent configuration using the official `prometheus-community/prometheus` chart in agent mode for metrics collection and forwarding to Mimir.

## Overview

The Prometheus Agent is a lightweight version of Prometheus that:

- **Scrapes metrics** from all exporters and Kubernetes components
- **Forwards data** to Mimir via remote write (no local storage)
- **Minimal resource usage** compared to full Prometheus server
- **Service discovery** for automatic target discovery in Kubernetes

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Exporters     │───▶│ Prometheus      │───▶│     Mimir       │
│                 │    │    Agent        │    │   (Storage)     │
│ • Node Exporter │    │                 │    │                 │
│ • Kube State    │    │ • Scrapes       │    │ • Long-term     │
│ • Blackbox      │    │ • Relabels      │    │   storage       │
│ • Nginx         │    │ • Remote Write  │    │ • Query engine  │
│ • Redis         │    │                 │    │                 │
│ • CloudWatch    │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Features

### **🎯 Comprehensive Scraping**

- **All exporters** automatically discovered via Kubernetes service discovery
- **Kubelet metrics** (cAdvisor for container metrics, node metrics)
- **Kubernetes API server** metrics
- **ServiceMonitor support** for automatic service discovery

### **🔄 Intelligent Remote Write**

- **Mimir integration** with optimized queue configuration
- **Automatic labeling** with cluster and environment information
- **Retry logic** with exponential backoff
- **Rate limiting** to prevent overwhelming Mimir

### **🔧 Service Discovery Jobs**

#### **Infrastructure Exporters**

```yaml
- node-exporter # Host system metrics
- kube-state-metrics # Kubernetes object state
- kubernetes-cadvisor # Container metrics via kubelet
- kubernetes-nodes # Node metrics via kubelet
- kubernetes-apiservers # API server metrics
```

#### **Application Exporters**

```yaml
- nginx-exporter # Web server performance
- redis-exporter # Database metrics
- aws-cloudwatch-exporter # AWS service metrics
```

#### **Synthetic Monitoring**

```yaml
- blackbox-exporter # Health checks and synthetic monitoring
```

### **🔒 Security & RBAC**

- **Service account** with minimal required permissions
- **RBAC** for Kubernetes API access (service discovery)
- **IRSA support** for AWS CloudWatch Exporter integration
- **Non-root execution** with security contexts

### **⚡ Performance Optimizations**

- **Agent mode** - no local storage, minimal memory footprint
- **Optimized scrape intervals** (30s default, 60s for CloudWatch)
- **Efficient relabeling** to reduce metric cardinality
- **Queue management** for remote write performance

## Configuration

### **Remote Write Target**

```yaml
remoteWrite:
  - url: "http://mimir-gateway.observability.svc.cluster.local:8080/api/v1/push"
    name: "mimir"
```

### **Global Labels**

```yaml
external_labels:
  cluster: "observability-cluster"
  environment: "production" # Override per environment
```

### **Scrape Configuration**

All exporters are automatically discovered using Kubernetes service discovery with proper relabeling for consistent metric naming.

## Deployment

### **Helm Installation**

```bash
# Add Prometheus Community repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Deploy Prometheus Agent
helm upgrade --install prometheus-agent prometheus-community/prometheus \
  --namespace observability --create-namespace \
  -f k8s/base/prometheus-agent/values.yaml
```

### **Environment-Specific Overrides**

Create environment-specific values files to override:

- `external_labels.environment`
- `remoteWrite.url` (if using different Mimir instances)
- Resource limits based on cluster size

## Monitoring Integration

### **Metrics Collected**

- **📊 Infrastructure**: CPU, memory, disk, network from all nodes
- **🏗️ Kubernetes**: Pod status, deployments, services, resource usage
- **🌐 Applications**: Web server traffic, database performance
- **☁️ AWS Services**: EKS, EC2, DynamoDB, S3, ALB metrics via CloudWatch
- **🔍 Synthetic**: Endpoint availability and response times

### **Labels Added**

All metrics are enriched with:

```yaml
cluster: "observability-cluster"
environment: "production"
kubernetes_namespace: "monitoring"
kubernetes_service_name: "node-exporter"
```

## Troubleshooting

### **Common Issues**

1. **Remote write failing**

   ```bash
   # Check Prometheus Agent logs
   kubectl logs -n observability -l app.kubernetes.io/name=prometheus-agent

   # Verify Mimir connectivity
   kubectl exec -n observability deploy/prometheus-agent -- wget -qO- http://mimir-gateway.observability.svc.cluster.local:8080/ready
   ```

2. **Service discovery issues**

   ```bash
   # Check RBAC permissions
   kubectl auth can-i list endpoints --as=system:serviceaccount:observability:prometheus-agent

   # Verify service endpoints
   kubectl get endpoints -n monitoring
   ```

3. **Missing metrics from exporters**

   ```bash
   # Check exporter service status
   kubectl get svc -n monitoring

   # Test exporter metrics endpoint
   kubectl port-forward -n monitoring svc/node-exporter 9100:9100
   curl http://localhost:9100/metrics
   ```

## Resource Requirements

### **Production Sizing**

```yaml
resources:
  limits:
    cpu: 500m # Scales with number of targets
    memory: 1Gi # ~100MB per 1000 active series
  requests:
    cpu: 100m
    memory: 256Mi
```

### **Scaling Considerations**

- **CPU**: Increases with scrape frequency and target count
- **Memory**: Grows with active time series and remote write queue
- **Network**: Proportional to metric volume and remote write frequency

This Prometheus Agent provides a production-ready, scalable foundation for metrics collection in your observability stack.
