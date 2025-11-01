# Grafana - Unified Observability Dashboards

Enterprise-ready Grafana deployment with integrated data sources and comprehensive dashboards for metrics, logs, and traces.

## Overview

Grafana provides the visualization and analysis layer for our observability platform, with native integration to:

- **Mimir** (Metrics) - Prometheus-compatible queries and alerting
- **Loki** (Logs) - LogQL queries with trace correlation
- **Tempo** (Traces) - Distributed tracing with service maps
- **OpenTelemetry** - Unified telemetry correlation across all signals

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Users       │    │     Grafana     │    │   Data Sources  │
│                 │    │                 │    │                 │
│ • Dashboards    │───▶│ • Visualization │───▶│ • Mimir (Query) │
│ • Alerts        │    │ • Correlation   │    │ • Loki (LogQL)  │
│ • Exploration   │    │ • Alerting      │    │ • Tempo (TraceQL)│
└─────────────────┘    └─────────────────┘    └─────────────────┘
                               │
                       ┌─────────────────┐
                       │   Dashboards    │
                       │                 │
                       │ • Infrastructure│
                       │ • Applications  │
                       │ • SLO/SLI      │
                       │ • Observability │
                       └─────────────────┘
```

## Features

### **Data Source Integration**

- **Mimir**: Default Prometheus-compatible data source with exemplar support
- **Loki**: Log aggregation with trace correlation via derived fields
- **Tempo**: Distributed tracing with service maps and trace-to-logs correlation

### **Dashboard Categories**

- **Observability**: OpenTelemetry Collector, Three Pillars overview
- **Infrastructure**: Kubernetes cluster, Node Exporter, exporters
- **Applications**: RED metrics, service performance, trace analysis
- **SLOs**: Error budget tracking, burn rate alerting, compliance dashboards

### **Advanced Features**

- **Trace Correlation**: Automatic linking between metrics, logs, and traces
- **Exemplars**: Jump from metrics to specific traces
- **Service Maps**: Visual service topology from trace data
- **Unified Alerting**: Modern alerting with notification policies

## Configuration Files

### **values.yaml** - Main Configuration

- **Security hardening**: Non-root containers, read-only filesystems
- **Data source provisioning**: Automated Mimir, Loki, Tempo setup
- **Dashboard provisioning**: Organized by category with auto-loading
- **Alerting configuration**: Contact points and notification policies
- **Performance tuning**: Resource limits, persistence, caching

### **dashboard-configmaps.yaml** - Dashboard Library

- **Pre-built dashboards** for all observability components
- **Organized structure** with folders (Observability, Infrastructure, Applications, SLOs)
- **Best practices** following Grafana dashboard design guidelines

## Data Source Correlation

### **Metrics ↔ Traces (Exemplars)**

```yaml
# Mimir configuration enables exemplars
jsonData:
  exemplarTraceIdDestinations:
    - name: trace_id
      datasourceUid: tempo
```

### **Logs ↔ Traces (Derived Fields)**

```yaml
# Loki configuration extracts trace IDs
derivedFields:
  - datasourceUid: tempo
    matcherRegex: "trace_id=(\\w+)"
    name: TraceID
    url: "$${__value.raw}"
```

### **Traces ↔ Metrics/Logs**

```yaml
# Tempo configuration links to other sources
tracesToLogs:
  datasourceUid: loki
  tags: ["job", "instance", "pod", "namespace"]
tracesToMetrics:
  datasourceUid: mimir
  tags: [{ key: "service.name", value: "service" }]
```

## Security Configuration

### **Pod Security**

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 65534
  runAsGroup: 65534
  fsGroup: 65534

containerSecurityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop: [ALL]
  readOnlyRootFilesystem: true
```

### **Network Security**

- **NetworkPolicy**: Restricts ingress/egress to required connections only
- **Service mesh ready**: Works with Istio/Linkerd for mTLS
- **Authentication**: Supports OIDC, LDAP, OAuth integration

### **Data Security**

- **Persistence encryption**: EBS encryption for dashboard storage
- **Secret management**: Kubernetes secrets for credentials
- **RBAC integration**: Kubernetes RBAC for fine-grained access

## Deployment

### **Via Helmfile (Recommended)**

```bash
# Deploy Grafana with all dependencies
helmfile apply --selector name=grafana

# Verify deployment
kubectl get pods -n observability -l app.kubernetes.io/name=grafana
```

### **Direct Helm Installation**

```bash
# Add Grafana repository
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install with custom values
helm upgrade --install grafana grafana/grafana \
  --namespace observability \
  -f k8s/base/grafana/values.yaml

# Apply dashboard ConfigMaps
kubectl apply -f k8s/base/grafana/dashboard-configmaps.yaml
```

### **Prerequisites**

1. **Storage**: GP3 StorageClass for persistence
2. **Data Sources**: Mimir, Loki, Tempo deployed and accessible
3. **Network**: Appropriate NetworkPolicies applied

## Access and Usage

### **Web UI Access**

```bash
# Port forward to access Grafana
kubectl port-forward -n observability svc/grafana 3000:80

# Open in browser
open http://localhost:3000

# Default credentials
Username: admin
Password: admin123!  # Change in production
```

### **Initial Setup**

1. **Login** with admin credentials
2. **Verify data sources** are connected (Admin → Data Sources)
3. **Import dashboards** or use pre-provisioned ones
4. **Configure alerting** (Alerting → Contact Points)
5. **Set up users/teams** (Administration → Users)

## Dashboard Library

### **Observability Dashboards**

- **OpenTelemetry Collector**: Processing rates, export success, queue utilization
- **Three Pillars Overview**: Unified view of metrics, logs, traces ingestion
- **Correlation Examples**: Cross-signal navigation patterns

### **Infrastructure Dashboards**

- **Kubernetes Cluster**: Node health, resource usage, capacity planning
- **Node Exporter**: System metrics, disk I/O, network traffic
- **Exporters Overview**: All 6 exporters with health and performance metrics

### **Application Dashboards**

- **RED Metrics**: Rate, Errors, Duration for all services
- **Service Maps**: Topology visualization from trace data
- **Performance Analysis**: Latency percentiles, error tracking

### **SLO Dashboards**

- **Error Budget Overview**: All 21 SLOs with burn rate visualization
- **Compliance Tracking**: SLO adherence over time
- **Alerting Status**: Active alerts and notification delivery

## Alerting Configuration

### **Unified Alerting Features**

- **Multi-dimensional alerting**: Labels and annotations support
- **Template-based notifications**: Customizable alert messages
- **Contact point routing**: Different notifications for different teams
- **Silence management**: Temporary alert suppression

### **Example Alert Rule**

```yaml
# High error rate alert
groups:
  - name: application-alerts
    rules:
      - alert: HighErrorRate
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m])) by (service) /
          sum(rate(http_requests_total[5m])) by (service) > 0.05
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High error rate detected for {{ $labels.service }}"
          description: "Error rate is {{ $value | humanizePercentage }}"
```

### **Notification Integration**

```yaml
# Slack notifications
contactPoints:
  - name: "slack-alerts"
    receivers:
      - type: slack
        settings:
          url: "YOUR_SLACK_WEBHOOK"
          channel: "#alerts"
          title: "{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}"
```

## Performance Tuning

### **Resource Optimization**

```yaml
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi

# Persistence for performance
persistence:
  enabled: true
  size: 10Gi
  storageClassName: gp3
```

### **Query Performance**

- **Query caching**: Enabled for frequently accessed dashboards
- **Data source optimization**: Connection pooling and timeouts
- **Dashboard variables**: Efficient templating reduces query load

## Troubleshooting

### **Common Issues**

1. **Data source connectivity**

   ```bash
   # Test Mimir connection
   kubectl exec -n observability deploy/grafana -- \
     wget -O- http://mimir-gateway:8080/prometheus/api/v1/query?query=up

   # Test Loki connection
   kubectl exec -n observability deploy/grafana -- \
     wget -O- http://loki-gateway:3100/ready

   # Test Tempo connection
   kubectl exec -n observability deploy/grafana -- \
     wget -O- http://tempo-gateway:3200/ready
   ```

2. **Dashboard loading issues**

   ```bash
   # Check dashboard ConfigMaps
   kubectl get configmaps -n observability -l grafana_dashboard=1

   # Verify sidecar logs
   kubectl logs -n observability deploy/grafana -c grafana-sc-dashboards
   ```

3. **Permission errors**

   ```bash
   # Check service account permissions
   kubectl describe sa grafana -n observability

   # Verify RBAC
   kubectl auth can-i --list --as=system:serviceaccount:observability:grafana
   ```

### **Monitoring Grafana**

```promql
# Query success rate
sum(rate(grafana_api_dataproxy_request_all_total[5m])) by (status_code)

# Dashboard load time
histogram_quantile(0.95, sum(rate(grafana_page_response_time_milliseconds_bucket[5m])) by (le))

# Active user sessions
grafana_stat_active_users
```

## Best Practices

### **Dashboard Design**

- **Consistent color schemes** across all dashboards
- **Meaningful time ranges** with appropriate refresh intervals
- **Template variables** for dynamic filtering
- **Alert annotations** linked to relevant runbooks

### **Performance**

- **Query optimization** with appropriate time ranges and step intervals
- **Panel caching** for expensive queries
- **Dashboard organization** with logical grouping and folders

### **Security**

- **Regular password rotation** for admin accounts
- **RBAC integration** for team-based access control
- **Audit logging** enabled for compliance requirements
- **Network isolation** via NetworkPolicies

## Grafana Operator Migration

### **Migration from Helm to Operator**

The Grafana setup has been migrated from **Helm chart** to **Grafana Operator** approach for better Kubernetes-native management.

#### **New Structure**

```
k8s/base/grafana/
├── operator/
│   ├── grafana-instance.yaml      # Main Grafana instance CRD
│   └── datasources.yaml           # Data source configurations
├── dashboards/
│   ├── infrastructure/            # Infrastructure dashboards
│   ├── observability-platform/    # Platform-specific dashboards
│   └── reliability/               # SLO monitoring dashboards
├── kustomization.yaml             # Orchestration configuration
├── values-operator.yaml           # Grafana Operator Helm values
└── README.md                      # This documentation
```

#### **Deployment Commands**

**1. Install Grafana Operator:**

```bash
# Add Grafana Operator Helm repository
helm repo add grafana-operator https://grafana.github.io/grafana-operator
helm repo update

# Install the operator
helm install grafana-operator grafana-operator/grafana-operator \
  --namespace grafana-system \
  --create-namespace \
  --values k8s/base/grafana/values-operator.yaml
```

**2. Deploy Grafana Instance & Resources:**

```bash
# Create observability namespace
kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -

# Deploy Grafana instance, data sources, and dashboards
kubectl apply -k k8s/base/grafana/

# Verify deployment
kubectl get grafana,grafanadatasource,grafanadashboard -n observability
```

**3. Access Grafana:**

```bash
# Port forward to access Grafana UI
kubectl port-forward -n observability svc/grafana-service 3000:80

# Open browser: http://localhost:3000
# Default credentials: admin / admin123!
```

#### **Operator vs Helm Benefits**

| Aspect           | Helm Chart                 | Grafana Operator         |
| ---------------- | -------------------------- | ------------------------ |
| **Management**   | Helm lifecycle             | Kubernetes-native CRDs   |
| **Dashboards**   | ConfigMaps + Sidecar       | GrafanaDashboard CRDs    |
| **Data Sources** | Static YAML provisioning   | GrafanaDataSource CRDs   |
| **Updates**      | `helm upgrade`             | `kubectl apply`          |
| **GitOps**       | Helm-based workflows       | Native Kubernetes GitOps |
| **Scaling**      | Manual resource management | Operator-managed         |

## OpenTelemetry Integration

### **Metrics Collection Architecture**

This platform uses **OpenTelemetry Collector** (not Prometheus directly) for unified telemetry collection:

```
📊 Metrics Flow:
┌─────────────┐    ┌─────────────────────┐    ┌─────────────┐
│   Grafana   │───▶│ OpenTelemetry       │───▶│    Mimir    │
│ (queries)   │    │ Collector           │    │ (storage)   │
└─────────────┘    │ (prometheus recv)   │    └─────────────┘
                   └─────────────────────┘
                            ▲
┌─────────────┐            │
│  Exporters  │────────────┘
│ + Grafana   │
└─────────────┘
```

### **Grafana Metrics Scraping**

Grafana instance uses **platform-specific annotations** for OpenTelemetry Collector discovery:

```yaml
# Grafana pod annotations (automatically added by operator)
annotations:
  observability.platform/scrape: "true"
  observability.platform/port: "3000"
  observability.platform/path: "/metrics"
  observability.platform/component: "grafana"
```

### **Available Grafana Metrics**

Once scraped by OpenTelemetry Collector, these metrics are available in Mimir:

- `grafana_http_request_duration_seconds` - Request latency
- `grafana_http_requests_total` - Request count by status
- `grafana_dashboard_views_total` - Dashboard popularity
- `grafana_datasource_request_duration_seconds` - Data source performance
- `grafana_alerting_active_alerts` - Active alerts count
- `process_cpu_seconds_total` - CPU usage
- `process_memory_bytes` - Memory usage

### **Configuration Verification**

To ensure Grafana metrics are collected, verify in OpenTelemetry Collector configuration:

```bash
# Check if Grafana target is discovered
kubectl logs -n observability daemonset/otel-collector | grep -i grafana

# Query Grafana metrics in Mimir
# Data source: Mimir, Query: grafana_http_requests_total
```

## Troubleshooting

### **Operator Issues**

```bash
# Check operator status
kubectl get pods -n grafana-system -l app.kubernetes.io/name=grafana-operator

# Check operator logs
kubectl logs -n grafana-system deployment/grafana-operator
```

### **Instance Issues**

```bash
# Check Grafana instance status
kubectl describe grafana -n observability grafana-instance

# Check Grafana pods
kubectl get pods -n observability -l app=grafana
```

### **Data Source Issues**

```bash
# Check data source CRDs
kubectl describe grafanadatasource -n observability

# Test connectivity from Grafana pod
kubectl exec -it -n observability <grafana-pod> -- curl http://mimir-gateway:8080/-/ready
```

This Grafana deployment provides **enterprise-grade visualization** with comprehensive dashboards, advanced correlation capabilities, Kubernetes-native operator management, and robust OpenTelemetry integration for your observability platform.
