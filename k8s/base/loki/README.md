# Loki - Log Aggregation and Storage

This directory contains Grafana Loki configuration using the official `grafana/loki` chart for scalable log aggregation and long-term storage.

## Overview

Loki is a horizontally scalable, highly available log aggregation system that provides:

- **Log Aggregation**: Collect logs from all Kubernetes pods via Promtail
- **Long-term Storage**: S3 backend with DynamoDB indexing for fast queries
- **Label-based Indexing**: Efficient log querying using labels instead of full-text indexing
- **LogQL Queries**: Powerful log analysis with Prometheus-style query language
- **Grafana Integration**: Native integration for log visualization and alerting

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Promtail      │───▶│      Loki       │───▶│   Grafana       │
│  (DaemonSet)    │    │   Gateway       │    │ (Log Queries)   │
│                 │    │ ┌─────────────┐ │    │                 │
│ Pod Log         │    │ │Write/Read   │ │    │                 │
│ Collection      │    │ │Components   │ │    │                 │
└─────────────────┘    │ └─────────────┘ │    └─────────────────┘
                       │ ┌─────────────┐ │
                       │ │  Backend    │ │────┐ ┌─────────────────┐
                       │ │ Processing  │ │    │ │  AWS Services   │
                       │ └─────────────┘ │    └▶│ • S3 (chunks)   │
                       └─────────────────┘      │ • DynamoDB (idx)│
                                               │ • KMS (encrypt) │
                                               └─────────────────┘
```

## Configuration Files

- **`values.template.yaml`**: Template with Terraform variable substitution
- **`values.yaml`**: Static configuration for reference
- **Generated at deploy**: `values.generated.yaml` (created by deployment script)

## AWS Integration

### **S3 Storage**

- **Chunks**: Log data stored in compressed chunks
- **Encryption**: KMS encryption for security
- **Lifecycle**: Cost optimization with IA/Glacier transitions

### **DynamoDB Indexing**

- **Fast Queries**: Label-based index for efficient log searches
- **Schema**: TSDB v13 with daily index rotation
- **Performance**: Pay-per-request billing for variable loads

### **IRSA Security**

- **No Credentials**: Secure AWS access via Kubernetes ServiceAccount
- **Least Privilege**: Minimal S3/DynamoDB permissions required

## SimpleScalable Deployment Mode

### **Write Components** (3 replicas)

- **Distributor**: Log ingestion from Promtail
- **Ingester**: Memory buffering and S3 flushing

### **Read Components** (3 replicas)

- **Querier**: LogQL query processing
- **Query Frontend**: Query optimization and caching

### **Backend Components** (3 replicas)

- **Compactor**: Log chunk compaction and retention
- **Index Gateway**: DynamoDB index access

## Deployment

### **Prerequisites**

1. Terraform AWS resources (S3, DynamoDB, IAM)
2. GP3 storage class in EKS cluster
3. Promtail for log collection

### **Helm Deployment**

```bash
# Via Helmfile (recommended)
helmfile apply --selector name=loki

# Or direct Helm
helm upgrade --install loki grafana/loki \
  --namespace observability \
  -f values.generated.yaml
```

### **With Promtail**

```bash
# Deploy log collection agent
helm upgrade --install promtail grafana/promtail \
  --namespace observability \
  -f k8s/base/promtail/values.yaml
```

## Validation

```bash
# Check Loki pods
kubectl get pods -n observability -l app.kubernetes.io/name=loki

# Check Promtail DaemonSet
kubectl get ds promtail -n observability

# Test log query
curl "http://loki-gateway.observability.svc.cluster.local:3100/loki/api/v1/query?query={namespace=\"default\"}"
```

## LogQL Examples

```logql
# Namespace logs
{namespace="observability"}

# Error logs with level parsing
{namespace="observability"} |= "error" | json | level="error"

# Error rate per pod
sum by (pod) (rate({namespace="observability"} |= "error" [5m]))
```

This Loki deployment provides enterprise-grade log aggregation with AWS integration and automatic Kubernetes log collection.
