# Development Environment Configuration

## 🧪 Development Environment Settings

**Purpose**: Local development and testing environment

### Environment Details

- **Cluster**: Local/Development cluster
- **Namespace**: `observability-dev`
- **Image Tag Strategy**: `latest` (rolling updates)
- **Auto-sync**: Enabled for rapid development

### Resource Allocation

- **CPU Limits**: Conservative (0.5-1 CPU per service)
- **Memory Limits**: Conservative (512Mi-1Gi per service)
- **Storage**: Local storage or minimal persistent volumes
- **Replicas**: Single replica for most services

### Monitoring Configuration

- **Metrics Retention**: 7 days
- **Log Retention**: 3 days
- **Alerting**: Basic alerting only
- **Dashboards**: Development-focused dashboards

### Access & Security

- **Ingress**: Local ingress (\*.dev.observability.local)
- **TLS**: Self-signed certificates acceptable
- **Authentication**: Basic auth or disabled for easier testing
- **RBAC**: Relaxed permissions for development

### Data Persistence

- **Prometheus**: 7 days retention, local storage
- **Grafana**: SQLite database
- **Loki**: 3 days retention, local storage
- **Tempo**: Minimal retention (1 day)

### Special Configurations

- **Debug Mode**: Enabled for all services
- **Log Level**: DEBUG
- **Metrics**: High-frequency collection for testing
- **Sampling**: 100% trace sampling

### Deployment Notes

- Fast deployment and rollback
- Auto-sync enabled for immediate feedback
- Resource requests are minimal
- Suitable for laptop/local development
