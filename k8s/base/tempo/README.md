# Tempo - Distributed Tracing Storage

This directory contains Tempo configuration using the official `grafana/tempo` chart for distributed tracing storage and querying.

## Overview

Grafana Tempo is a high-scale distributed tracing backend that provides:

- **Multi-Protocol Ingestion**: OTLP, Jaeger, Zipkin trace receivers
- **S3 Backend Storage**: Cost-effective long-term trace storage
- **High Performance**: Efficient trace storage and fast queries
- **Metrics Generation**: Automatic metrics generation from traces
- **Grafana Integration**: Native integration for trace visualization

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   APPLICATION   │    │    TEMPO        │    │    STORAGE      │    │    QUERYING     │
│    TRACING      │    │  DISTRIBUTOR    │    │                 │    │                 │
│                 │    │                 │    │                 │    │                 │
│ • OTLP gRPC     │───▶│ • Protocol      │───▶│ • S3 Blocks     │◀───│ • Query         │
│ • OTLP HTTP     │    │   Translation   │    │ • Parquet       │    │   Frontend      │
│ • Jaeger        │    │ • Load Balance  │    │ • Compression   │    │ • Trace Search  │
│ • Zipkin        │    │ • Validation    │    │                 │    │ • TraceQL       │
└─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                       │                       │
                                ▼                       ▼                       ▼
                       ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
                       │    INGESTER     │    │   COMPACTOR     │    │    QUERIER      │
                       │                 │    │                 │    │                 │
                       │ • Block         │    │ • Block         │    │ • Trace         │
                       │   Creation      │    │   Compaction    │    │   Retrieval     │
                       │ • WAL           │    │ • Retention     │    │ • Search        │
                       │ • Flushing      │    │ • Optimization  │    │ • Aggregation   │
                       └─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Configuration Files

### **values.yaml** - Local Storage Configuration

- SimpleScalable deployment mode with single replica
- Local storage for development environments
- All trace protocols enabled (OTLP, Jaeger, Zipkin)
- 7-day retention policy for cost optimization

### **values.template.yaml** - S3 Backend Configuration

- SimpleScalable deployment mode with multiple replicas
- S3 + KMS encryption for production storage
- IRSA integration for secure AWS access
- 10-day retention with automated lifecycle policies
- Metrics generation with remote write to Mimir

## Protocol Support

### **OpenTelemetry (OTLP)**

```yaml
# gRPC receiver
ports:
  - name: otlp-grpc
    port: 4317
    targetPort: 4317

  # HTTP receiver
  - name: otlp-http
    port: 4318
    targetPort: 4318
```

### **Jaeger Protocol**

```yaml
# gRPC receiver
- name: jaeger-grpc
  port: 14250
  targetPort: 14250

# HTTP receiver
- name: jaeger-http
  port: 14268
  targetPort: 14268

# Thrift Binary (UDP)
- name: jaeger-thrift-binary
  port: 6832
  targetPort: 6832
  protocol: UDP

# Thrift Compact (UDP)
- name: jaeger-thrift-compact
  port: 6831
  targetPort: 6831
  protocol: UDP
```

### **Zipkin Protocol**

```yaml
# HTTP receiver
- name: zipkin
  port: 9411
  targetPort: 9411
```

## Storage Configuration

### **S3 Backend (Production)**

```yaml
storage:
  trace:
    backend: s3
    s3:
      bucket: ${tempo_s3_bucket_name}
      region: ${aws_region}
      # Server-side encryption
      sse_config:
        type: "SSE-KMS"
        kms_key_id: "${kms_key_id}"
```

### **Local Backend (Development)**

```yaml
storage:
  trace:
    backend: local
    local:
      path: /var/tempo/traces
```

## Metrics Generation

Tempo can automatically generate metrics from traces:

```yaml
metrics_generator:
  registry:
    external_labels:
      source: tempo
      cluster: observability-cluster
  storage:
    remote_write:
      - url: http://mimir-gateway.observability.svc.cluster.local:8080/api/v1/push
        send_exemplars: true
```

### **Generated Metrics**

- **Request Rate**: `traces_spanmetrics_calls_total`
- **Request Duration**: `traces_spanmetrics_latency`
- **Error Rate**: `traces_spanmetrics_calls_total{status_code="ERROR"}`
- **Service Graph**: Service topology and dependencies

## Deployment

### **Helm Installation**

```bash
# Via Helmfile (recommended)
helmfile apply --selector name=tempo

# Or direct Helm
helm upgrade --install tempo grafana/tempo \
  --namespace observability --create-namespace \
  -f k8s/base/tempo/values.yaml
```

### **With S3 Backend**

```bash
# Template values with Terraform outputs first
./deploy.sh template

# Deploy with S3 backend
helm upgrade --install tempo grafana/tempo \
  --namespace observability \
  -f k8s/base/tempo/values.generated.yaml
```

### **Prerequisites**

1. **Kubernetes Cluster**: v1.19+ with persistent storage
2. **S3 Bucket**: For production deployments (optional)
3. **IAM Role**: IRSA role with S3 access (if using S3)
4. **Storage Class**: For persistent volumes

## Application Integration

### **OpenTelemetry SDK**

```python
# Python example
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# Configure tracer
trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)

# Configure exporter
otlp_exporter = OTLPSpanExporter(
    endpoint="http://tempo-gateway.observability.svc.cluster.local:4317",
    insecure=True
)

# Add processor
span_processor = BatchSpanProcessor(otlp_exporter)
trace.get_tracer_provider().add_span_processor(span_processor)
```

### **Jaeger Client**

```go
// Go example
import (
    "github.com/uber/jaeger-client-go/config"
)

func initTracer() {
    cfg := &config.Configuration{
        ServiceName: "my-service",
        Sampler: &config.SamplerConfig{
            Type:  "const",
            Param: 1,
        },
        Reporter: &config.ReporterConfig{
            LocalAgentHostPort: "tempo-gateway.observability.svc.cluster.local:6832",
        },
    }

    tracer, closer, err := cfg.NewTracer()
    // Handle error and use tracer
}
```

### **Kubernetes Pod Annotation**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    metadata:
      annotations:
        # Inject Jaeger agent sidecar
        sidecar.jaegertracing.io/inject: "true"
    spec:
      containers:
        - name: my-app
          image: my-app:latest
          env:
            - name: JAEGER_ENDPOINT
              value: "http://tempo-gateway.observability.svc.cluster.local:14268/api/traces"
```

## Querying Traces

### **TraceQL Queries**

```sql
-- Find traces by service
{ .service.name = "my-service" }

-- Find slow traces
{ duration > 1s }

-- Find error traces
{ .status = error }

-- Complex query
{ .service.name = "frontend" && .http.status_code = 500 && duration > 100ms }
```

### **Grafana Integration**

```yaml
# Grafana datasource configuration
apiVersion: 1
datasources:
  - name: Tempo
    type: tempo
    access: proxy
    url: http://tempo-gateway.observability.svc.cluster.local
    jsonData:
      httpMethod: GET
      tracesToLogs:
        datasourceUid: loki
        tags: ["job", "instance", "pod", "namespace"]
      tracesToMetrics:
        datasourceUid: mimir
        tags: [{ key: "service.name", value: "service" }]
      nodeGraph:
        enabled: true
```

## Monitoring & Observability

### **Key Metrics**

```promql
# Ingestion rate
rate(tempo_distributor_ingestion_requests_total[5m])

# Query success rate
rate(tempo_query_frontend_requests_total{status_code="200"}[5m])
/ rate(tempo_query_frontend_requests_total[5m])

# Storage utilization
tempo_ingester_blocks_flushed_total

# Compaction rate
rate(tempo_compactor_compaction_total[5m])
```

### **Health Checks**

```bash
# Check Tempo readiness
curl http://tempo-gateway.observability.svc.cluster.local/ready

# Check metrics endpoint
curl http://tempo-gateway.observability.svc.cluster.local/metrics

# Validate trace ingestion
curl -X POST http://tempo-gateway.observability.svc.cluster.local:14268/api/traces \
  -H "Content-Type: application/json" \
  -d '{"data": [{"traceID": "test", "spans": []}]}'
```

### **SLO Monitoring**

The included `slo-tempo.yaml` defines 4 SLOs:

- **Ingestion Availability**: 99.5% of traces ingested successfully
- **Query Availability**: 99% of queries succeed
- **Query Latency**: 95% of queries complete within 2s
- **Compaction Success**: 99% of compaction operations succeed

## Troubleshooting

### **Common Issues**

1. **Traces not appearing**

   ```bash
   # Check distributor logs
   kubectl logs -n observability -l app.kubernetes.io/name=tempo,app.kubernetes.io/component=distributor

   # Verify protocol endpoints
   kubectl get svc -n observability tempo -o yaml

   # Test trace submission
   curl -v -X POST http://tempo:4318/v1/traces \
     -H "Content-Type: application/json" \
     -d '{"resourceSpans":[]}'
   ```

2. **High storage usage**

   ```bash
   # Check compaction status
   kubectl logs -n observability -l app.kubernetes.io/name=tempo,app.kubernetes.io/component=compactor

   # Verify retention settings
   kubectl get configmap -n observability tempo -o yaml

   # Monitor S3 bucket size
   aws s3 ls s3://your-tempo-bucket --recursive --summarize
   ```

3. **Query performance issues**

   ```bash
   # Check querier logs
   kubectl logs -n observability -l app.kubernetes.io/name=tempo,app.kubernetes.io/component=querier

   # Monitor query metrics
   curl http://tempo:3100/metrics | grep tempo_query

   # Verify index cache
   kubectl exec -n observability deploy/tempo -- cat /var/tempo/cache/stats
   ```

### **Performance Tuning**

1. **Ingestion Optimization**

   ```yaml
   # Increase distributor replicas
   distributor:
     replicas: 3

   # Tune ingester settings
   ingester:
     max_block_duration: 10m
     max_block_bytes: 2_147_483_648 # 2GB
   ```

2. **Query Optimization**

   ```yaml
   # Enable query caching
   query_frontend:
     search:
       cache:
         enable_fifocache: true
         fifocache:
           max_size_bytes: 1073741824 # 1GB
   ```

3. **Storage Optimization**
   ```yaml
   # Compression settings
   storage:
     trace:
       block:
         bloom_filter_false_positive: 0.01
         index_downsample_bytes: 1000
         encoding: zstd
   ```

## Best Practices

### **Sampling Strategy**

- **Head Sampling**: Sample at application level (1-10% for high traffic)
- **Tail Sampling**: Use Tempo's intelligent sampling based on errors/latency
- **Adaptive Sampling**: Adjust rates based on service performance

### **Trace Structure**

- **Meaningful Names**: Use descriptive operation names
- **Rich Attributes**: Add relevant tags and metadata
- **Error Handling**: Properly mark error spans
- **Correlation**: Link traces with logs and metrics

### **Resource Management**

- **Resource Limits**: Set appropriate CPU/memory limits
- **Storage Classes**: Use fast storage for ingesters
- **Network**: Ensure sufficient bandwidth for trace ingestion
- **Monitoring**: Track key performance indicators

This Tempo deployment provides high-performance distributed tracing with multi-protocol support, S3 backend storage, and comprehensive monitoring integration.
