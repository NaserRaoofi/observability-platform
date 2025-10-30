# Grafana + OpenTelemetry Integration Guide

## 🎯 **Why This Configuration is Correct**

Your observability platform uses **OpenTelemetry Collector** (not Prometheus directly) for metrics collection:

```
📊 Metrics Architecture:
┌─────────────┐    ┌─────────────────────┐    ┌─────────────┐
│   Grafana   │───▶│ OpenTelemetry       │───▶│    Mimir    │
│ (metrics)   │    │ Collector           │    │ (storage)   │
└─────────────┘    │ (prometheus recv)   │    └─────────────┘
                   └─────────────────────┘           ▲
                            ▲                        │
┌─────────────┐            │                        │
│  Exporters  │────────────┘              ┌─────────┴─────────┐
│ (6 types)   │                          │ Grafana queries   │
└─────────────┘                          │ from Mimir        │
                                         └───────────────────┘
```

## ✅ **Your Current Annotations Are Perfect**

The Grafana Operator instance you created has the **correct annotations**:

```yaml
# Your grafana-instance.yaml annotations:
annotations:
  observability.platform/scrape: "true" # ✅ Correct
  observability.platform/port: "3000" # ✅ Correct
  observability.platform/path: "/metrics" # ✅ Correct
  observability.platform/component: "grafana" # ✅ Correct
```

These use **your platform's custom annotation scheme** instead of the standard `prometheus.io/*` annotations.

## 🔧 **Required: Add Grafana to OpenTelemetry Collector**

Your OTel Collector (`k8s/base/otel-collector/values.yaml`) scrapes:

- ✅ Node Exporter
- ✅ Kube State Metrics
- ✅ All 6 exporters (blackbox, nginx, redis, etc.)
- ✅ Mimir, Loki, Tempo components
- ❌ **Missing: Grafana**

### **Add This to OTel Collector Config**

Insert around line 175 in `k8s/base/otel-collector/values.yaml`, after the Tempo scraping config:

```yaml
# Grafana metrics
- job_name: "grafana"
  kubernetes_sd_configs:
    - role: pod
      namespaces:
        names: ["observability"]
  relabel_configs:
    # Target pods with platform scrape annotation
    - source_labels: [__meta_kubernetes_pod_annotation_observability_platform_scrape]
      action: keep
      regex: "true"
    - source_labels: [__meta_kubernetes_pod_annotation_observability_platform_component]
      action: keep
      regex: "grafana"
    # Use the port from annotation
    - source_labels: [__meta_kubernetes_pod_annotation_observability_platform_port]
      action: replace
      target_label: __address__
      regex: (.+)
      replacement: ${__meta_kubernetes_pod_ip}:${1}
    # Use the metrics path from annotation
    - source_labels: [__meta_kubernetes_pod_annotation_observability_platform_path]
      action: replace
      target_label: __metrics_path__
      regex: (.+)
    # Add consistent labels
    - target_label: job
      replacement: grafana
    - source_labels: [__meta_kubernetes_pod_name]
      target_label: instance
  scrape_interval: 30s
  metrics_path: /metrics
```

## 📊 **What Grafana Metrics You'll Get**

Once OTel Collector scrapes Grafana, you'll see these metrics in Mimir:

### **Core Grafana Metrics**

- `grafana_http_request_duration_seconds` - Request latency
- `grafana_http_requests_total` - Request count by status
- `grafana_api_user_signins_fail_total` - Failed logins
- `grafana_database_connections_open` - DB connections
- `grafana_alerting_active_alerts` - Active alerts count

### **Dashboard Metrics**

- `grafana_dashboard_views_total` - Dashboard popularity
- `grafana_datasource_request_duration_seconds` - Data source performance
- `grafana_plugins_build_info` - Plugin information

### **System Metrics**

- `process_cpu_seconds_total` - CPU usage
- `process_memory_bytes` - Memory usage
- `go_memstats_*` - Go runtime metrics

## 🔍 **Verification Commands**

After updating OTel Collector config:

```bash
# 1. Restart OTel Collector to pick up new config
kubectl rollout restart daemonset/otel-collector -n observability

# 2. Check if Grafana target is discovered
kubectl logs -n observability daemonset/otel-collector | grep -i grafana

# 3. Query Grafana metrics in Mimir (via Grafana itself)
# Use Mimir data source, query: grafana_http_requests_total

# 4. Port-forward to see OTel Collector targets
kubectl port-forward -n observability daemonset/otel-collector 8888:8888
# Visit: http://localhost:8888/debug/pprof
```

## 🎯 **Why NOT ServiceMonitor**

❌ **ServiceMonitor** is a **Prometheus Operator** CRD
✅ **Your platform** uses **OpenTelemetry Collector** with annotation-based discovery

Your approach is actually **better** because:

- 🔄 **Unified collection** - All metrics through OTel
- 📊 **Richer metadata** - OTLP format vs Prometheus
- 🔧 **Platform consistency** - Same pattern for all components
- 🚀 **Future-proof** - OpenTelemetry is the CNCF standard

## 📋 **Summary of Changes Made**

1. **✅ Updated Grafana Operator annotations** - Use platform-specific discovery
2. **✅ Removed ServiceMonitor** - Not needed for OTel-based platform
3. **📝 Documented OTel integration** - Add Grafana to scrape config
4. **🎯 Explained architecture** - Why this approach is correct

Your **Grafana Operator configuration is now correctly aligned** with your **OpenTelemetry-based observability platform**! 🎉
