# Grafana Dashboards Organization

This directory contains Grafana dashboards organized by functional categories for better navigation and management.

## 📁 Folder Structure

```
dashboards/
├── infrastructure/           # Infrastructure & Platform Health
│   ├── alertmanager-overview.yaml    # Alert management and routing
│   └── kubernetes-cluster.yaml       # K8s cluster health and resources
│
├── observability-platform/  # Observability Stack Components
│   ├── otel-collector.yaml          # OpenTelemetry data pipeline
│   ├── mimir-overview.yaml          # Metrics storage (Prometheus)
│   ├── loki-overview.yaml           # Log storage and ingestion
│   └── tempo-overview.yaml          # Trace storage and queries
│
└── reliability/             # Service Reliability & SLOs
    └── slo-monitoring.yaml          # SLO tracking and error budgets
```

## 🎯 Dashboard Categories

### **Infrastructure**

Monitors the underlying platform and infrastructure health:

- **Kubernetes Cluster**: Node health, resource usage, pod status
- **AlertManager**: Alert routing, notification delivery, firing rates

### **Observability Platform**

Monitors the observability stack components themselves:

- **OpenTelemetry Collector**: Data processing rates, export success, pipeline health
- **Mimir**: Metrics ingestion, storage health, query performance
- **Loki**: Log ingestion, storage metrics, query latency
- **Tempo**: Trace ingestion, storage health, query performance

### **Reliability**

Monitors service level objectives and reliability metrics:

- **SLO Monitoring**: Error budget tracking, SLI compliance, service reliability

## 🚀 Adding New Dashboards

When adding new dashboards:

1. **Choose appropriate folder** based on dashboard purpose
2. **Update folder reference** in the GrafanaDashboard CRD:
   ```yaml
   spec:
     folder: "Infrastructure" # or "Observability Platform" or "Reliability"
   ```
3. **Add to kustomization.yaml** under the corresponding section
4. **Update this README** if adding new categories

## 📊 Dashboard Access

In Grafana UI, dashboards will be organized into folders:

- **Infrastructure** - Platform and cluster monitoring
- **Observability Platform** - Stack component health
- **Reliability** - SLO and service reliability metrics

This organization provides clear separation of concerns and easier navigation for different user personas (platform engineers, SRE teams, application developers).
