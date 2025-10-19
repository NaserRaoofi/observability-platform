# OpenTelemetry Collector - Unified Observability Pipeline

OpenTelemetry Collector provides a unified pipeline for collecting, processing, and exporting telemetry data (metrics, logs, and traces).

## Purpose

- **Unified Collection**: Single agent for metrics, logs, and traces
- **Vendor Agnostic**: Works with any observability backend
- **Advanced Processing**: Rich set of processors for data transformation
- **Multi-layer Architecture**: Gateway and agent deployment patterns

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
