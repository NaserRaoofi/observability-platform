# Staging Environment Configuration

## 🏗️ Staging Environment Settings

**Purpose**: Pre-production testing and validation environment

### Environment Details

- **Cluster**: Staging cluster (production-like)
- **Namespace**: `observability-staging`
- **Image Tag Strategy**: Semantic versioning (v1.2.3)
- **Auto-sync**: Disabled (manual sync required)

### Resource Allocation

- **CPU Limits**: Production-like (1-2 CPU per service)
- **Memory Limits**: Production-like (1-4Gi per service)
- **Storage**: Production-like persistent storage
- **Replicas**: 2-3 replicas for high availability testing

### Monitoring Configuration

- **Metrics Retention**: 30 days
- **Log Retention**: 14 days
- **Alerting**: Full alerting stack (non-critical)
- **Dashboards**: Production-ready dashboards

### Access & Security

- **Ingress**: External ingress (\*.staging.observability.com)
- **TLS**: Valid certificates required
- **Authentication**: Production-like authentication
- **RBAC**: Production-equivalent RBAC

### Data Persistence

- **Prometheus**: 30 days retention, persistent storage
- **Grafana**: PostgreSQL database
- **Loki**: 14 days retention, object storage
- **Tempo**: 7 days retention, object storage

### Special Configurations

- **Debug Mode**: Disabled
- **Log Level**: INFO
- **Metrics**: Production-like collection intervals
- **Sampling**: 10% trace sampling

### Quality Gates

- **Performance Testing**: Required before promotion
- **Security Scanning**: Full security validation
- **Integration Testing**: End-to-end testing required
- **Load Testing**: Capacity validation

### Deployment Process

1. Manual sync required for all changes
2. Approval process for critical changes
3. Rollback procedures tested
4. Performance benchmarks validated

### Promotion Criteria

- All tests pass in staging
- Performance meets SLAs
- Security scans clear
- Manual approval from platform team
