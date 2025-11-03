# Production Environment Configuration

## 🚀 Production Environment Settings

**Purpose**: Live production environment serving real workloads

### Environment Details

- **Cluster**: Production cluster (multi-zone)
- **Namespace**: `observability-prod`
- **Image Tag Strategy**: Stable semantic versions only
- **Auto-sync**: Disabled (manual sync with approvals)

### Resource Allocation

- **CPU Limits**: Production-optimized (2-4 CPU per service)
- **Memory Limits**: Production-optimized (4-16Gi per service)
- **Storage**: High-performance persistent storage
- **Replicas**: 3+ replicas with anti-affinity rules

### Monitoring Configuration

- **Metrics Retention**: 90 days (long-term analysis)
- **Log Retention**: 30 days (compliance requirements)
- **Alerting**: Full alerting with PagerDuty integration
- **Dashboards**: Executive and operational dashboards

### Access & Security

- **Ingress**: Production ingress (\*.observability.com)
- **TLS**: Valid certificates with automatic renewal
- **Authentication**: Enterprise SSO/OIDC required
- **RBAC**: Strict production RBAC policies

### Data Persistence

- **Prometheus**: 90 days retention, distributed storage
- **Grafana**: HA PostgreSQL cluster
- **Loki**: 30 days retention, S3-compatible storage
- **Tempo**: 14 days retention, distributed object storage

### High Availability

- **Multi-Zone**: Resources spread across availability zones
- **Backup Strategy**: Automated backups every 6 hours
- **Disaster Recovery**: Cross-region replication
- **RTO/RPO**: 15 minutes RTO, 1 hour RPO

### Security Controls

- **Network Policies**: Strict network segmentation
- **Pod Security**: Pod Security Standards enforced
- **Image Scanning**: Only signed and scanned images
- **Secrets Management**: External secret management (Vault/CSI)

### Compliance & Governance

- **Audit Logging**: All changes logged and retained
- **Change Management**: Formal change approval process
- **Compliance**: SOC2/ISO27001 controls
- **Documentation**: All changes documented

### Maintenance Windows

- **Scheduled Maintenance**: Sunday 02:00-04:00 UTC
- **Emergency Changes**: Follow incident response process
- **Rollback Plan**: Automated rollback capabilities
- **Communication**: Stakeholder notifications required

### SLA Requirements

- **Availability**: 99.9% uptime SLA
- **Performance**: < 2s query response time
- **Alert Response**: Critical alerts < 5 minutes
- **Data Loss**: Zero data loss policy

### Deployment Process

1. Staging validation must pass
2. Security review required
3. Platform team approval mandatory
4. Maintenance window scheduling
5. Rollback plan documented
6. Post-deployment validation
