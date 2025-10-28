# AlertManager - Alert Routing and Notification

AlertManager handles alerts sent by client applications such as the Prometheus server. It takes care of deduplicating, grouping, and routing them to the correct receiver integration such as email, PagerDuty, or Slack.

## Overview

AlertManager provides:

- **Alert Deduplication**: Groups identical alerts together
- **Alert Routing**: Routes alerts to appropriate receivers based on labels
- **Notification Management**: Handles retry logic and notification delivery
- **Silencing**: Temporary suppression of alerts
- **Inhibition**: Suppresses alerts based on other active alerts

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Sloth       │    │  AlertManager   │    │  Notification   │
│  (SLO Alerts)   │───▶│                 │───▶│   Channels      │
│                 │    │ • Grouping      │    │                 │
│ • Burn Rate     │    │ • Routing       │    │ • Email/Slack   │
│ • Error Budget  │    │ • Deduplication │    │ • PagerDuty     │
│ • Multi-Window  │    │ • Inhibition    │    │ • Webhooks      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Mimir/Prom    │    │    Grafana      │    │   External      │
│   (AlertRules)  │    │  (Visualization)│    │   Systems       │
│                 │    │                 │    │                 │
│ • Recording     │    │ • Alert Status  │    │ • Ticketing     │
│ • Alerting      │    │ • Dashboards    │    │ • Chat Apps     │
│ • Evaluation    │    │ • Annotations   │    │ • Escalation    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Configuration Files

### **values.yaml** - Helm Configuration

- AlertManager deployment configuration
- Storage and persistence settings
- Service and ingress configuration
- Resource limits and security contexts

### **alertmanager-config.yaml** - Alert Routing

- Routing rules based on alert labels
- Receiver definitions for different notification channels
- Grouping and timing configurations
- Inhibition and silencing rules

### **notification-templates.yaml** - Alert Templates

- Custom notification templates for different channels
- Rich formatting for Slack, Teams, email
- SLO-specific alert formatting
- Escalation message templates

## Integration Points

### **Sloth SLO Integration**

- Receives burn rate alerts from Sloth-generated PrometheusRules
- Routes SLO alerts based on severity and component
- Provides error budget notifications
- Escalates based on burn rate velocity

### **Mimir Integration**

- Evaluates alerting rules stored in Mimir
- Receives fired alerts via webhook
- Queries Mimir for alert context and metrics
- Stores alert state and history

### **Grafana Integration**

- Grafana displays AlertManager status and alerts
- Provides unified alert visualization
- Shows SLO dashboard integration
- Alert annotation in time series

## Alert Routing Strategy

### **Severity Levels**

- **Critical**: Immediate escalation (SLO fast burn)
- **High**: 15-minute escalation (SLO medium burn)
- **Warning**: 1-hour escalation (SLO slow burn)
- **Info**: Notification only (SLO degradation)

### **Component-Based Routing**

- **Infrastructure**: Platform team alerts
- **Application**: Development team alerts
- **Security**: Security team alerts
- **Compliance**: Audit team alerts

### **Time-Based Routing**

- **Business Hours**: Full escalation chain
- **After Hours**: Critical alerts only
- **Weekends**: Reduced escalation for non-critical
- **Holiday**: Emergency contacts only

## Notification Channels

### **Supported Integrations**

- **Slack**: Team channels with rich formatting
- **Email**: Distribution lists and individual notifications
- **PagerDuty**: Incident management integration
- **Microsoft Teams**: Office 365 integration
- **Webhook**: Custom integrations and automation
- **OpsGenie**: Alternative incident management

## Security Considerations

### **Access Control**

- RBAC for AlertManager UI access
- Service accounts for webhook authentication
- Secret management for notification credentials
- Network policies for external communication

### **Data Protection**

- Alert data encryption in transit and at rest
- Sensitive information masking in notifications
- Audit logging for alert management actions
- Retention policies for alert history

## Deployment

### **Helm Installation**

```bash
# Via Helmfile (recommended)
helmfile apply --selector name=alertmanager

# Or direct Helm
helm upgrade --install alertmanager prometheus-community/alertmanager \
  --namespace observability \
  -f k8s/base/alertmanager/values.yaml
```

### **Configuration Management**

```bash
# Apply AlertManager configuration
kubectl apply -f k8s/base/alertmanager/alertmanager-config.yaml

# Apply notification templates
kubectl apply -f k8s/base/alertmanager/notification-templates.yaml

# Verify configuration
kubectl exec -n observability alertmanager-0 -- \
  amtool config show
```

## Operations

### **Alert Management**

```bash
# View active alerts
kubectl port-forward -n observability svc/alertmanager 9093:9093
# Open http://localhost:9093

# Silence alerts
amtool silence add alertname="HighMemoryUsage" --duration=1h

# Query alerts via API
curl http://alertmanager.observability.svc.cluster.local:9093/api/v2/alerts
```

### **Testing and Validation**

```bash
# Test notification channels
amtool config routes test --config.file=/etc/alertmanager/config.yml

# Send test alert
curl -XPOST http://alertmanager:9093/api/v1/alerts -H "Content-Type: application/json" -d '[{
  "labels": {
    "alertname": "TestAlert",
    "severity": "warning"
  }
}]'

# Check alert routing
amtool config routes show --config.file=/etc/alertmanager/config.yml
```

## Monitoring AlertManager

### **Key Metrics**

- `alertmanager_alerts_received_total`: Total alerts received
- `alertmanager_alerts_invalid_total`: Invalid alerts rejected
- `alertmanager_notifications_sent_total`: Notifications sent by channel
- `alertmanager_notifications_failed_total`: Failed notification attempts
- `alertmanager_silences_active`: Currently active silences

### **Health Checks**

- HTTP endpoint: `/api/v2/status`
- Configuration reload: `POST /-/reload`
- Ready status: `/api/v2/status`
- Metrics endpoint: `/metrics`

## Best Practices

### **Alert Design**

- Use meaningful alert names and descriptions
- Include runbook links in alert annotations
- Set appropriate severity levels
- Use consistent labeling for routing

### **Notification Strategy**

- Avoid alert fatigue with proper grouping
- Use different channels for different severities
- Implement escalation chains for critical alerts
- Test notification channels regularly

### **Maintenance**

- Regular configuration reviews
- Clean up outdated silences
- Monitor notification delivery rates
- Update contact information periodically
