# Sloth - SLI/SLO Monitoring

This directory contains Sloth configuration using the official `sloth/sloth` chart for automated SLI/SLO monitoring and alerting.

## Overview

Sloth is a tool that generates Prometheus recording rules and alerting rules based on SLI/SLO definitions that provides:

- **SLO Management**: Define Service Level Objectives using Kubernetes CRDs
- **Automated Alerting**: Generate multi-window, multi-burn-rate alerts
- **Error Budget Tracking**: Monitor error budget consumption and burn rate
- **Prometheus Integration**: Native integration with Prometheus/Mimir for metrics
- **Grafana Dashboards**: Auto-generated dashboards for SLO visualization

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│      SLO        │───▶│     Sloth       │───▶│   Prometheus    │
│  Definitions    │    │   Controller    │    │     Rules       │
│   (CRDs)        │    │                 │    │                 │
│                 │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ • Mimir SLOs    │    │ │ Rule        │ │    │ │ Recording   │ │
│ • Loki SLOs     │    │ │ Generator   │ │────┤ │ Rules       │ │
│ • Infra SLOs    │    │ └─────────────┘ │    │ └─────────────┘ │
└─────────────────┘    │ ┌─────────────┐ │    │ ┌─────────────┐ │
                       │ │ Alert       │ │    │ │ Alerting    │ │
                       │ │ Generator   │ │────┤ │ Rules       │ │
                       │ └─────────────┘ │    │ └─────────────┘ │
                       └─────────────────┘    └─────────────────┘
                                                       │
                                              ┌─────────────────┐
                                              │   Grafana       │
                                              │  Dashboards     │
                                              │                 │
                                              │ • Error Budget  │
                                              │ • Burn Rate     │
                                              │ • SLO Status    │
                                              └─────────────────┘
```

## SLO Definitions

### **Mimir SLOs** (`slo-mimir.yaml`)

- **Request Availability**: 99.9% of requests should succeed
- **Query Latency**: 99% of queries under 1 second
- **Ingestion Success**: 99.5% of metrics ingestion should succeed

### **Loki SLOs** (`slo-loki.yaml`)

- **Ingestion Availability**: 99.5% of log ingestion should succeed
- **Query Availability**: 99% of log queries should succeed
- **Query Latency**: 95% of queries under 5 seconds
- **Data Freshness**: 98% of logs appear within 30 seconds

### **Infrastructure SLOs** (`slo-infrastructure.yaml`)

- **Stack Availability**: 99.5% of components should be healthy
- **Monitoring Coverage**: 95% of nodes should have monitoring
- **Data Retention**: 99.9% compliance with retention policies
- **Storage Performance**: 99% of operations within acceptable time
- **Alert Processing**: 99.5% of alerts processed successfully

## Multi-Window, Multi-Burn-Rate Alerting

Sloth generates sophisticated alerting rules based on error budget burn rate:

### **Alert Severity Levels**

- **Critical**: Fast burn rate (2% budget in 1 hour)
- **High**: Medium burn rate (5% budget in 6 hours)
- **Medium**: Slow burn rate (10% budget in 1 day)
- **Low**: Very slow burn rate (10% budget in 3 days)

### **Alert Windows**

```yaml
# Example multi-window alert
- alert: MimirAvailabilityErrorBudgetBurn
  expr: |
    (
      mimir_slo_error_budget_burn_rate{slo="requests-availability"} > 14.4
      and
      mimir_slo_error_budget_burn_rate{slo="requests-availability"}[1h] > 14.4
    )
    or
    (
      mimir_slo_error_budget_burn_rate{slo="requests-availability"} > 6
      and
      mimir_slo_error_budget_burn_rate{slo="requests-availability"}[6h] > 6
    )
```

## Error Budget Tracking

### **Error Budget Calculation**

```promql
# Error budget remaining
slo_error_budget_remaining{service="mimir"} =
  (1 - slo_objective) - slo_current_error_rate

# Burn rate (how fast budget is consumed)
slo_error_budget_burn_rate{service="mimir"} =
  slo_current_error_rate / (1 - slo_objective)
```

### **Budget Consumption Alerts**

- **90% Consumed**: Warning alert
- **95% Consumed**: Critical alert
- **100% Consumed**: SLO violation alert

## Configuration

### **Prometheus Integration**

```yaml
config:
  prometheus:
    url: "http://mimir-gateway.observability.svc.cluster.local:8080/prometheus"
```

### **Custom Resource Definitions**

Sloth uses Kubernetes CRDs for SLO management:

```yaml
apiVersion: sloth.slok.dev/v1
kind: PrometheusServiceLevel
metadata:
  name: my-service-slo
spec:
  service: "my-service"
  slos:
    - name: "availability"
      objective: 99.9
      sli:
        events:
          errorQuery: "sum(rate(http_requests_errors[5m]))"
          totalQuery: "sum(rate(http_requests_total[5m]))"
```

## Deployment

### **Helm Installation**

```bash
# Via Helmfile (recommended)
helmfile apply --selector name=sloth

# Or direct Helm
helm upgrade --install sloth sloth/sloth \
  --namespace observability --create-namespace \
  -f k8s/base/sloth/values.yaml
```

### **Deploy SLO Definitions**

```bash
# Apply all SLO definitions
kubectl apply -f k8s/base/sloth/slo-*.yaml

# Apply individual SLOs
kubectl apply -f k8s/base/sloth/slo-mimir.yaml
kubectl apply -f k8s/base/sloth/slo-loki.yaml
```

### **Prerequisites**

1. **Prometheus/Mimir**: Running metrics system for rule evaluation
2. **CRD Support**: Kubernetes cluster with CRD support
3. **Metrics Data**: Existing metrics to calculate SLIs from

## Monitoring & Dashboards

### **Generated Recording Rules**

```promql
# SLI calculations (auto-generated)
slo:sli_error:ratio_rate5m{service="mimir", slo="availability"}
slo:sli_error:ratio_rate30m{service="mimir", slo="availability"}
slo:sli_error:ratio_rate1h{service="mimir", slo="availability"}
slo:sli_error:ratio_rate6h{service="mimir", slo="availability"}

# Error budget calculations
slo:error_budget:ratio{service="mimir", slo="availability"}
slo:burn_rate:ratio{service="mimir", slo="availability"}
```

### **Grafana Integration**

```json
{
  "dashboard": {
    "title": "SLO Dashboard",
    "panels": [
      {
        "title": "Error Budget Remaining",
        "targets": [
          {
            "expr": "slo:error_budget:ratio{service=\"$service\"}"
          }
        ]
      },
      {
        "title": "Burn Rate",
        "targets": [
          {
            "expr": "slo:burn_rate:ratio{service=\"$service\"}"
          }
        ]
      }
    ]
  }
}
```

## Validation

### **Check Sloth Controller**

```bash
# Check pod status
kubectl get pods -n observability -l app.kubernetes.io/name=sloth

# Check controller logs
kubectl logs -n observability -l app.kubernetes.io/name=sloth

# Check generated rules
kubectl get prometheusrule -n observability
```

### **Verify SLO Definitions**

```bash
# List all SLOs
kubectl get prometheusservicelevel -n observability

# Check specific SLO status
kubectl describe prometheusservicelevel mimir-availability-slo -n observability

# Validate SLO metrics
curl "http://mimir-gateway.observability.svc.cluster.local:8080/prometheus/api/v1/query?query=slo:sli_error:ratio_rate5m"
```

### **Test Alerting Rules**

```bash
# Check if rules are loaded
kubectl get prometheusrule -n observability -o yaml

# Test rule evaluation
promtool query instant \
  'http://mimir-gateway.observability.svc.cluster.local:8080/prometheus' \
  'slo:error_budget:ratio{service="mimir"}'
```

## Troubleshooting

### **Common Issues**

1. **SLO not generating rules**

   ```bash
   # Check SLO validation
   kubectl describe prometheusservicelevel -n observability

   # Check Sloth controller logs
   kubectl logs -n observability -l app.kubernetes.io/name=sloth
   ```

2. **Missing metrics for SLI calculation**

   ```bash
   # Verify base metrics exist
   curl "http://mimir-gateway:8080/prometheus/api/v1/query?query=mimir_request_total"

   # Check metric labels match SLO queries
   kubectl get prometheusservicelevel mimir-availability-slo -o yaml
   ```

3. **Alerts not firing**

   ```bash
   # Check Prometheus rule evaluation
   kubectl exec -n observability deploy/mimir-ruler -- \
     wget -qO- http://localhost:8080/api/v1/rules | jq '.data.groups[].rules[]'

   # Verify alert manager configuration
   kubectl logs -n observability -l app.kubernetes.io/name=alertmanager
   ```

## Best Practices

### **SLO Design**

- **Start Simple**: Begin with basic availability and latency SLOs
- **User-Centric**: Define SLOs based on user experience, not technical metrics
- **Realistic Objectives**: Set achievable targets (99.9% often too aggressive)
- **Business Alignment**: Ensure SLOs align with business requirements

### **Alert Configuration**

- **Multi-Window**: Use multiple time windows to reduce noise
- **Burn Rate**: Focus on error budget burn rate, not absolute error rate
- **Severity Mapping**: Map alert severity to business impact
- **Runbooks**: Provide clear runbook links for all alerts

### **Error Budget Management**

- **Regular Review**: Review error budgets in planning meetings
- **Feature Velocity**: Use error budget to guide feature release decisions
- **Incident Response**: Factor SLO impact into incident severity
- **Continuous Improvement**: Adjust SLOs based on operational learnings

This Sloth deployment provides comprehensive SLO monitoring with automated alerting and error budget tracking for your entire observability stack.
