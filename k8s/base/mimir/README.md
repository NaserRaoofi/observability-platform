# Mimir - Long-term Metrics Storage

This directory contains Grafana Mimir configuration using the official `grafana/mimir-distributed` chart for scalable, long-term metrics storage and querying.

## Overview

Mimir is a horizontally scalable, highly available, multi-tenant time series database for Prometheus that provides:

- **Long-term storage** with S3 backend and DynamoDB for metadata
- **High availability** with replication and sharding
- **Multi-tenancy** support for isolation
- **Advanced querying** with PromQL support
- **Alerting and recording rules** via ruler component

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Prometheus      │───▶│     Mimir       │───▶│   Grafana       │
│   Agent         │    │   Gateway       │    │  (Queries)      │
│                 │    │                 │    │                 │
│ Remote Write    │    │ ┌─────────────┐ │    │                 │
│                 │    │ │ Distributor │ │    │                 │
│                 │    │ └─────────────┘ │    │                 │
└─────────────────┘    │ ┌─────────────┐ │    └─────────────────┘
                       │ │  Ingester   │ │
                       │ └─────────────┘ │
                       │ ┌─────────────┐ │
                       │ │   Querier   │ │    ┌─────────────────┐
                       │ └─────────────┘ │───▶│  AWS Services   │
                       │ ┌─────────────┐ │    │                 │
                       │ │Store Gateway│ │    │ • S3 (blocks)   │
                       │ └─────────────┘ │    │ • DynamoDB (idx)│
                       │ ┌─────────────┐ │    │ • Redis (cache) │
                       │ │  Compactor  │ │    └─────────────────┘
                       │ └─────────────┘ │
                       └─────────────────┘
```

## Components

### **🚪 Gateway (nginx)**

- **Purpose**: Single entry point for all Mimir services
- **Replicas**: 2 for high availability
- **Endpoints**: `/api/v1/push` (write), `/prometheus/api/v1/query` (read)

### **📡 Distributor**

- **Purpose**: Receives metrics from Prometheus Agent, validates, and forwards to ingesters
- **Replicas**: 3 for load distribution
- **Features**: Rate limiting, validation, sharding

### **💾 Ingester**

- **Purpose**: Writes metrics to memory and periodically flushes to S3
- **Replicas**: 3 with replication factor 3
- **Storage**: 50GB persistent volumes for WAL (Write-Ahead Log)
- **Features**: In-memory time series, compression, deduplication

### **🔍 Querier**

- **Purpose**: Executes PromQL queries against ingester and store gateway
- **Replicas**: 2 for query load balancing
- **Features**: Query optimization, result caching

### **🎯 Query Frontend**

- **Purpose**: Optimizes and parallelizes queries, provides caching layer
- **Replicas**: 2 for high availability
- **Cache**: Redis backend for query results

### **🏪 Store Gateway**

- **Purpose**: Provides access to historical blocks stored in S3
- **Replicas**: 3 for data availability
- **Storage**: 100GB persistent volumes for block cache
- **Features**: Block indexing, metadata caching

### **🔄 Compactor**

- **Purpose**: Compacts and deduplicates blocks, applies retention policies
- **Replicas**: 1 (single instance to avoid conflicts)
- **Storage**: 50GB persistent volumes for temporary data
- **Retention**: 7 years (2555 days) as configured

### **📏 Ruler**

- **Purpose**: Evaluates recording rules and alerting rules
- **Replicas**: 2 for high availability
- **Features**: Rule evaluation, alert generation

### **🚨 Alertmanager**

- **Purpose**: Handles alerts sent by ruler
- **Replicas**: 3 for high availability
- **Storage**: 10GB persistent volumes for alert state

## Storage Architecture

### **AWS S3 Integration**

```yaml
# Long-term block storage
s3:
  bucket_name: "observability-mimir-metrics"
  region: "us-west-2"
  sse:
    type: SSE-KMS
    kms_key_id: "${kms_key_id}" # From Terraform
```

### **DynamoDB Integration**

- **Index storage**: Ring membership, chunk metadata
- **Tables**: Created by Terraform module
- **Performance**: Pay-per-request billing for variable workloads

### **Redis Caching**

- **Query result cache**: Speeds up repeated queries
- **Metadata cache**: Reduces DynamoDB load
- **Endpoint**: `redis-master.default.svc.cluster.local:6379`

## Security & IRSA

### **Service Account Configuration**

```yaml
serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: ${mimir_irsa_role_arn}
```

### **Required AWS Permissions**

- **S3**: Full access to Mimir metrics bucket
- **DynamoDB**: Read/write access to Mimir tables
- **KMS**: Decrypt/encrypt permissions for S3 SSE

### **Security Contexts**

- **Non-root execution**: User 65534
- **Read-only filesystems**: Enhanced security
- **Dropped capabilities**: Minimal privileges

## Performance Configuration

### **Resource Allocation**

```yaml
# High-load components
ingester:
  resources:
    requests: { cpu: 1000m, memory: 2Gi }
    limits: { cpu: 2000m, memory: 4Gi }

compactor:
  resources:
    requests: { cpu: 1000m, memory: 2Gi }
    limits: { cpu: 2000m, memory: 4Gi }

# Query components
querier:
  resources:
    requests: { cpu: 500m, memory: 1Gi }
    limits: { cpu: 1000m, memory: 2Gi }
```

### **Storage Performance**

- **GP3 volumes**: Better IOPS and throughput than GP2
- **Persistent volumes**: Separate for each component's needs
- **Cache optimization**: Redis for frequently accessed data

### **Limits Configuration**

```yaml
limits:
  ingestion_rate: 50000 # Samples per second per tenant
  max_global_series_per_user: 10M # Maximum active series
  max_query_length: 32d # Maximum query time range
  compactor_blocks_retention: 2555d # 7 years retention
```

## High Availability Features

### **Replication**

- **Ingester replication**: Factor of 3 for data durability
- **Component redundancy**: Multiple replicas for all services
- **Cross-AZ deployment**: Anti-affinity rules spread pods

### **Pod Disruption Budgets**

```yaml
podDisruptionBudget:
  ingester:
    minAvailable: 2 # Maintain quorum during updates
  distributor:
    minAvailable: 2 # Keep accepting writes
  store_gateway:
    minAvailable: 2 # Maintain query capability
```

## Monitoring Integration

### **ServiceMonitor**

- **Automatic discovery**: Prometheus Agent scrapes all components
- **Metrics endpoint**: `/metrics` on port 8080
- **Labels**: `app.kubernetes.io/part-of: observability-stack`

### **Key Metrics to Monitor**

```promql
# Ingestion rate
rate(mimir_distributor_samples_in_total[5m])

# Query performance
histogram_quantile(0.99, rate(mimir_request_duration_seconds_bucket[5m]))

# Storage usage
mimir_ingester_memory_series

# Error rates
rate(mimir_request_errors_total[5m])
```

## Deployment

### **Helm Installation**

```bash
# Add Grafana repository
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Deploy Mimir
helm upgrade --install mimir grafana/mimir-distributed \
  --namespace observability --create-namespace \
  -f k8s/base/mimir/values.yaml
```

### **Prerequisites**

1. **AWS Resources**: S3 bucket, DynamoDB tables, IAM roles (from Terraform)
2. **Redis**: Running Redis instance for caching
3. **Storage Class**: GP3 storage class configured in EKS

### **Validation**

```bash
# Check component health
kubectl get pods -n observability -l app.kubernetes.io/name=mimir

# Test write endpoint
curl -X POST http://mimir-gateway.observability.svc.cluster.local:8080/api/v1/push

# Test query endpoint
curl "http://mimir-gateway.observability.svc.cluster.local:8080/prometheus/api/v1/query?query=up"
```

## Troubleshooting

### **Common Issues**

1. **IRSA permissions**

   ```bash
   # Check service account
   kubectl describe sa mimir -n observability

   # Test S3 access from pod
   kubectl exec -n observability deploy/mimir-distributor -- aws s3 ls s3://observability-mimir-metrics/
   ```

2. **Storage issues**

   ```bash
   # Check PVC status
   kubectl get pvc -n observability

   # Check storage class
   kubectl get storageclass gp3
   ```

3. **Component communication**

   ```bash
   # Check service endpoints
   kubectl get endpoints -n observability

   # Check memberlist ring
   kubectl logs -n observability -l app.kubernetes.io/component=distributor
   ```

## Scaling Considerations

### **Horizontal Scaling**

- **Distributor**: Scale based on write load
- **Ingester**: Add replicas for higher ingestion rate
- **Querier**: Scale based on query volume
- **Store Gateway**: Scale for better read performance

### **Vertical Scaling**

- **Memory**: Increase for larger active series sets
- **CPU**: Scale for higher compression/query workloads
- **Storage**: Adjust PV sizes based on data retention needs

This Mimir deployment provides a production-ready, scalable metrics storage solution with AWS integration, high availability, and comprehensive monitoring.
