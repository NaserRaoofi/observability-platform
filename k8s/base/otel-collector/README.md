# OpenTelemetry Collector - Unified Observability Pipeline

This directory contains OpenTelemetry Collector configurations using the official `open-telemetry/opentelemetry-collector` chart for comprehensive telemetry collection and processing.

## Overview

OpenTelemetry Collector provides a unified, vendor-agnostic pipeline for collecting, processing, and exporting telemetry data (metrics, logs, and traces) with:

- **Multi-Protocol Support**: OTLP, Jaeger, Zipkin, Prometheus receivers
- **Advanced Processing**: Rich set of processors for data transformation and enrichment
- **Multi-Layer Architecture**: Agent (DaemonSet) and Gateway (Deployment) patterns
- **High Performance**: Efficient batching, queuing, and export mechanisms
- **Observability**: Built-in metrics and health checks for monitoring

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   APPLICATION   │    │  OTEL COLLECTOR │    │  OTEL COLLECTOR │    │    BACKENDS     │
│    TELEMETRY    │    │     AGENT       │    │     GATEWAY     │    │                 │
│                 │    │   (DaemonSet)   │    │  (Deployment)   │    │                 │
│ • OTLP gRPC     │───▶│                 │───▶│                 │───▶│ • Mimir (PromRW)│
│ • OTLP HTTP     │    │ • Receive       │    │ • Advanced      │    │ • Tempo (OTLP)  │
│ • Jaeger        │    │ • Basic Proc.   │    │   Processing    │    │ • Loki (HTTP)   │
│ • Zipkin        │    │ • K8s Metadata  │    │ • Sampling      │    │                 │
│ • Prometheus    │    │ • Forward       │    │ • Correlation   │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                       │
                       ┌─────────────────┐    ┌─────────────────┐
                       │   HOST/POD      │    │   TRACE TO      │
                       │    METRICS      │    │    METRICS      │
                       │                 │    │                 │
                       │ • kubeletstats  │    │ • spanmetrics   │
                       │ • hostmetrics   │    │ • servicegraph  │
                       │ • filelog       │    │ • exemplars     │
                       └─────────────────┘    └─────────────────┘
```

## Configuration Files

### **values.yaml** - Agent Configuration (DaemonSet)

- **Node-level collection**: Deployed on every node as DaemonSet
- **Host metrics**: CPU, memory, disk, network from hosts
- **Pod logs**: Kubernetes pod logs with metadata enrichment
- **Kubelet stats**: Container and pod metrics from kubelet
- **Basic processing**: Memory limiting, batching, K8s attributes
- **Forward to gateway**: All data sent to gateway for advanced processing

### **values-gateway.yaml** - Gateway Configuration (Deployment)

- **Centralized processing**: Multiple replicas for high availability
- **Advanced processors**: Sampling, correlation, transformation
- **Trace to metrics**: Automatic RED metrics generation from traces
- **Service topology**: Service graph generation for dependency mapping
- **Export optimization**: Efficient batching and retry logic
- **Multi-backend export**: Simultaneous export to Mimir, Loki, Tempo

## Receivers Configuration

### **Agent Receivers**

```yaml
receivers:
  # OTLP for modern applications
  otlp:
    protocols:
      grpc: # Port 4317
      http: # Port 4318

  # Legacy protocol support
  jaeger: # Ports 14250, 14268, 6832, 6831
  zipkin: # Port 9411

  # Infrastructure metrics
  kubeletstats: # Container/pod metrics
  hostmetrics: # CPU, memory, disk, network
  filelog: # Kubernetes pod logs
```

### **Gateway Receivers**

```yaml
receivers:
  # From agents and direct applications
  otlp: # Aggregation point
  jaeger: # Direct app connections
  zipkin: # Direct app connections
  prometheus: # Own metrics
```

## Processing Pipeline

### **Agent Processing**

```yaml
processors:
  memory_limiter: # OOM protection
  k8sattributes: # Kubernetes metadata
  resource: # Cluster information
  resourcedetection: # Cloud metadata
  batch: # Efficiency batching
```

### **Gateway Processing**

```yaml
processors:
  memory_limiter: # Higher limits
  tail_sampling: # Intelligent sampling
    policies:
      - error-sampling # Always sample errors
      - latency-sampling # Sample slow requests
      - probabilistic-sampling # 5% of normal traces

  span: # Span enrichment
  attributes: # Data sanitization
  transform: # Advanced manipulation
  groupbyattrs: # Cardinality control
```

## Data Correlation

### **Trace to Metrics Generation**

```yaml
connectors:
  spanmetrics:
    # Generate RED metrics from traces
    histogram_buckets: [100us, 1ms, 10ms, 100ms, 1s, 10s]
    dimensions:
      - http.method
      - http.status_code
      - service.version
    exemplars: true # Link metrics back to traces

  servicegraph:
    # Generate service topology
    dimensions:
      - service.namespace
      - service.version
```

### **Correlation Features**

- **Exemplars**: Link metrics to specific traces
- **Service Graph**: Automatic service dependency mapping
- **Trace Context**: Propagate correlation across all signals
- **Resource Attributes**: Consistent labeling across telemetry

## Export Configuration

### **Multi-Backend Export**

```yaml
exporters:
  # Traces to Tempo
  otlp/tempo:
    endpoint: tempo-gateway:4317

  # Metrics to Mimir
  prometheusremotewrite/mimir:
    endpoint: http://mimir-gateway:8080/api/v1/push

  # Logs to Loki
  loki:
    endpoint: http://loki-gateway:3100/loki/api/v1/push
```

### **Reliability Features**

- **Persistent Queues**: File-based storage for retry
- **Retry Logic**: Exponential backoff with jitter
- **Circuit Breakers**: Prevent cascade failures
- **Load Balancing**: Multiple backend endpoints

## Deployment

### **Helm Installation**

```bash
# Deploy both agent and gateway
helmfile apply --selector name=otel-collector

# Or deploy individually
helm upgrade --install otel-collector-agent open-telemetry/opentelemetry-collector \
  --namespace observability -f k8s/base/otel-collector/values.yaml

helm upgrade --install otel-collector-gateway open-telemetry/opentelemetry-collector \
  --namespace observability -f k8s/base/otel-collector/values-gateway.yaml
```

### **Prerequisites**

1. **Kubernetes**: v1.19+ with DaemonSet support
2. **Backends**: Mimir, Loki, Tempo deployed and accessible
3. **RBAC**: Service accounts with appropriate permissions
4. **Resources**: Adequate CPU/memory for telemetry processing

## Application Integration

### **OTLP Instrumentation**

```python
# Python example
from opentelemetry import trace, metrics, logs
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter

# Configure exporters to OTel Collector
trace_exporter = OTLPSpanExporter(
    endpoint="http://otel-collector-gateway.observability.svc.cluster.local:4317"
)

metric_exporter = OTLPMetricExporter(
    endpoint="http://otel-collector-gateway.observability.svc.cluster.local:4317"
)
```

### **Kubernetes Annotation**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    metadata:
      annotations:
        # Auto-configure OTEL endpoint
        opentelemetry.io/inject: "true"
    spec:
      containers:
        - name: my-app
          env:
            - name: OTEL_EXPORTER_OTLP_ENDPOINT
              value: "http://otel-collector-gateway.observability.svc.cluster.local:4317"
            - name: OTEL_SERVICE_NAME
              value: "my-app"
            - name: OTEL_RESOURCE_ATTRIBUTES
              value: "service.version=1.0.0,deployment.environment=dev"
```

### **Java Auto-Instrumentation**

```bash
# Download Java agent
wget https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar

# Run with instrumentation
java -javaagent:opentelemetry-javaagent.jar \
     -Dotel.exporter.otlp.endpoint=http://otel-collector-gateway.observability.svc.cluster.local:4317 \
     -Dotel.service.name=my-java-app \
     -jar my-app.jar
```

## Monitoring & Observability

### **Collector Metrics**

```promql
# Processing throughput
rate(otelcol_processor_accepted_spans_total[5m])
rate(otelcol_processor_accepted_metric_points_total[5m])
rate(otelcol_processor_accepted_log_records_total[5m])

# Export success rate
rate(otelcol_exporter_sent_spans_total[5m]) /
rate(otelcol_exporter_sent_spans_total[5m] + otelcol_exporter_send_failed_spans_total[5m])

# Queue utilization
otelcol_exporter_queue_size / otelcol_exporter_queue_capacity

# Memory usage
otelcol_process_memory_rss / otelcol_process_memory_limit
```

### **Health Checks**

```bash
# Agent health check
kubectl port-forward ds/otel-collector-agent 13133:13133
curl http://localhost:13133/

# Gateway health check
kubectl port-forward deploy/otel-collector-gateway 13133:13133
curl http://localhost:13133/

# Internal metrics
curl http://localhost:8888/metrics

# zpages diagnostics
kubectl port-forward deploy/otel-collector-gateway 55679:55679
# Open http://localhost:55679/debug/tracez
```

### **SLO Monitoring**

The included `slo-otel-collector.yaml` defines 5 SLOs:

- **Processing Success Rate**: 99.5% of data processing succeeds
- **Export Success Rate**: 99% of exports to backends succeed
- **Queue Utilization**: 95% of time queue usage under 80%
- **Receiver Availability**: 99.9% of receiver endpoints available
- **Memory Usage**: 95% of time memory usage under 80% limit

## Troubleshooting

### **Common Issues**

1. **Data not flowing**

   ```bash
   # Check receiver endpoints
   kubectl get svc -n observability | grep otel-collector

   # Check processor metrics
   kubectl port-forward deploy/otel-collector-gateway 8888:8888
   curl http://localhost:8888/metrics | grep otelcol_processor

   # Check exporter metrics
   curl http://localhost:8888/metrics | grep otelcol_exporter
   ```

2. **High memory usage**

   ```bash
   # Check memory limiter
   kubectl logs -n observability -l app.kubernetes.io/name=opentelemetry-collector

   # Adjust batch settings
   # Reduce batch_size and timeout in values.yaml

   # Check queue sizes
   curl http://localhost:8888/metrics | grep queue_size
   ```

3. **Export failures**

   ```bash
   # Check backend connectivity
   kubectl exec -n observability deploy/otel-collector-gateway -- \
     wget -O- http://mimir-gateway.observability.svc.cluster.local:8080/ready

   # Check retry queues
   kubectl logs -n observability deploy/otel-collector-gateway | grep "export"

   # Validate exporter configuration
   kubectl get configmap -n observability otel-collector-gateway -o yaml
   ```

### **Performance Tuning**

1. **Agent Optimization**

   ```yaml
   # Increase batch sizes for efficiency
   batch:
     send_batch_size: 2048
     timeout: 2s

   # Tune memory limits
   memory_limiter:
     limit_mib: 512
     spike_limit_mib: 128
   ```

2. **Gateway Optimization**

   ```yaml
   # Enable persistent queues
   file_storage:
     directory: /tmp/otel_storage

   # Optimize sampling
   tail_sampling:
     decision_wait: 5s # Reduce for lower latency
     num_traces: 100000 # Increase for high throughput
   ```

3. **Resource Scaling**
   ```yaml
   # Enable HPA for gateway
   autoscaling:
     enabled: true
     minReplicas: 2
     maxReplicas: 10
     targetCPUUtilizationPercentage: 70
   ```

## Best Practices

### **Configuration Management**

- **Layer Separation**: Use agent for collection, gateway for processing
- **Resource Limits**: Set appropriate memory limits to prevent OOM
- **Batch Tuning**: Balance latency vs. efficiency based on traffic
- **Sampling Strategy**: Use tail sampling for intelligent trace selection

### **Security**

- **TLS Configuration**: Enable TLS for production deployments
- **Authentication**: Use mTLS or API keys for backend access
- **Data Sanitization**: Remove sensitive data in processors
- **Network Policies**: Restrict collector network access

### **Operational Excellence**

- **Monitoring**: Monitor collector health and performance metrics
- **Alerting**: Set up alerts for high error rates and resource usage
- **Capacity Planning**: Scale based on telemetry volume growth
- **Documentation**: Maintain runbooks for common issues

This OpenTelemetry Collector deployment provides a comprehensive, production-ready telemetry pipeline with advanced processing capabilities, multi-backend support, and extensive monitoring integration.

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Applications  │───▶│ OTel Collector  │───▶│  Observability  │
│                 │    │   (Agent)       │    │    Backends     │
│ • Metrics       │    │                 │    │                 │
│ • Logs          │    │ • Receives      │    │ • Mimir         │
│ • Traces        │    │ • Processes     │    │ • Loki          │
└─────────────────┘    │ • Exports       │    │ • Tempo         │
                       └─────────────────┘    └─────────────────┘
```

## Components

### **Agent Mode (DaemonSet)**

- **Log Collection**: Filelog receiver for container logs
- **Metrics Collection**: Host metrics and Kubernetes metrics
- **Trace Collection**: OTLP and Jaeger receivers

### **Gateway Mode (Deployment)**

- **Centralized Processing**: Advanced processors and sampling
- **Load Balancing**: Distributes load across backend systems
- **Tail Sampling**: Intelligent trace sampling decisions

## Log Collection Capabilities

```yaml
receivers:
  filelog:
    include: ["/var/log/pods/*/*/*.log"]
    include_file_name: false
    include_file_path: true
    operators:
      - type: json_parser
        timestamp:
          parse_from: attributes.time
          layout_type: gotime
          layout: "2006-01-02T15:04:05.000000000Z"
      - type: add
        field: attributes.log_source
        value: kubernetes

processors:
  k8sattributes:
    extract:
      metadata:
        - k8s.pod.name
        - k8s.pod.uid
        - k8s.deployment.name
        - k8s.namespace.name
        - k8s.node.name

exporters:
  loki:
    endpoint: http://loki:3100/loki/api/v1/push
    tenant_id: "tenant-1"
```

## Multi-layer Deployment

### **Agent Layer (Node-level)**

- Collects telemetry from applications and infrastructure
- Minimal processing for low latency
- Forwards to gateway layer

### **Gateway Layer (Cluster-level)**

- Advanced processing and sampling
- Backend-specific formatting
- Load balancing and failover

## Integration with Observability Stack

- **→ Mimir**: Metrics export via remote_write
- **→ Loki**: Logs export via Loki API
- **→ Tempo**: Traces export via OTLP
- **← Applications**: Receives via OTLP, Jaeger, Zipkin protocols

## Benefits Over Dedicated Collectors

✅ **Single Agent**: Reduces operational overhead
✅ **Consistent Processing**: Same processing pipeline for all telemetry
✅ **Resource Efficiency**: Shared infrastructure and configuration
✅ **Vendor Flexibility**: Easy to switch backends without changing collection
✅ **Rich Ecosystem**: Extensive processor and receiver library

## Use Cases

- **Unified Observability**: When you want one agent for everything
- **Multi-backend**: Sending data to multiple observability systems
- **Advanced Processing**: Complex data transformation requirements
- **Vendor Migration**: Switching between observability vendors
- **Cost Optimization**: Sampling and filtering to reduce backend costs
