# 🔥 Error Rate Spike Runbook

## 🚨 **Alert: High Error Rate Detected**

This runbook provides systematic procedures for investigating and resolving error rate spikes across the observability platform and monitored services.

## 📊 **Alert Definitions**

```yaml
# Error rate thresholds
Warning:  > 5% error rate for 5 minutes
Critical: > 10% error rate for 2 minutes
P0:       > 25% error rate for 1 minute
```

## 🔍 **Initial Triage (First 5 Minutes)**

### **1. Assess Scope and Impact**

```bash
# Check overall platform health
kubectl get pods -n monitoring --watch

# Quick service status check
curl -s http://mimir-gateway:8080/-/ready
curl -s http://loki-gateway:3100/ready
curl -s http://tempo-gateway:3100/ready
```

### **2. Identify Error Sources**

#### **Check Grafana Dashboards**

1. **Service Overview Dashboard** - Look for red panels
2. **Error Rate by Service** - Identify which services are affected
3. **SLO Dashboard** - Check if SLOs are breached

#### **Quick Log Analysis**

```bash
# Check recent errors in Loki
kubectl port-forward svc/loki-gateway 3100:3100 &
curl -G -s "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={level="error"}' \
  --data-urlencode 'start='$(date -d '10 minutes ago' -u +%s)'000000000' \
  --data-urlencode 'end='$(date -u +%s)'000000000'
```

### **3. Platform Component Health Check**

```bash
# Check observability platform components
kubectl get pods -n monitoring -o wide | grep -E "(0/|Error|CrashLoop|Pending)"

# Check resource usage
kubectl top pods -n monitoring --sort-by=cpu
kubectl top pods -n monitoring --sort-by=memory

# Check events for errors
kubectl get events -n monitoring --sort-by='.lastTimestamp' | tail -20
```

## 🎯 **Systematic Investigation**

### **Phase 1: Infrastructure Layer**

#### **1. Kubernetes Cluster Health**

```bash
# Node status
kubectl get nodes -o wide
kubectl describe nodes | grep -A5 -B5 "Conditions:"

# Network policies and connectivity
kubectl get networkpolicies -n monitoring
kubectl exec -it <pod-name> -n monitoring -- nslookup kubernetes.default.svc.cluster.local
```

#### **2. AWS Backend Services**

```bash
# Check DynamoDB table status
aws dynamodb describe-table --table-name mimir-index-dev
aws dynamodb describe-table --table-name loki-index-dev

# Check S3 bucket accessibility
aws s3 ls s3://observability-mimir-dev/
aws s3 ls s3://observability-loki-dev/

# Check IAM role permissions
aws sts get-caller-identity
aws iam simulate-principal-policy --policy-source-arn <service-role-arn> --action-names s3:GetObject --resource-arns <bucket-arn>/*
```

#### **3. Load Balancer and Ingress**

```bash
# Check ingress status
kubectl get ingress -n monitoring
kubectl describe ingress <ingress-name> -n monitoring

# Test service endpoints
kubectl get svc -n monitoring
kubectl exec -it <test-pod> -- curl -v http://mimir-gateway:8080/api/v1/query?query=up
```

### **Phase 2: Application Layer**

#### **1. Mimir Component Analysis**

```bash
# Check Mimir distributor logs
kubectl logs -l app.kubernetes.io/component=distributor -n monitoring --tail=100

# Check Mimir ingester status
kubectl exec -it mimir-ingester-0 -n monitoring -- wget -qO- http://localhost:8080/-/ready

# Verify Mimir configuration
kubectl get configmap mimir-config -n monitoring -o yaml

# Check Mimir metrics
kubectl port-forward svc/mimir-gateway 8080:8080 &
curl "http://localhost:8080/prometheus/api/v1/query?query=cortex_ingester_memory_series"
```

#### **2. Loki Component Analysis**

```bash
# Check Loki write path
kubectl logs -l app.kubernetes.io/component=write -n monitoring --tail=100

# Check Loki read path
kubectl logs -l app.kubernetes.io/component=read -n monitoring --tail=100

# Test Loki ingestion
echo '{"streams": [{ "stream": { "job": "test" }, "values": [ [ "'$(date +%s%N)'", "test log line" ] ] }]}' | \
curl -X POST "http://localhost:3100/loki/api/v1/push" \
  -H "Content-Type: application/json" \
  --data-binary @-
```

#### **3. OpenTelemetry Collector Analysis**

```bash
# Check OTel Collector status
kubectl logs -l app=opentelemetry-collector -n monitoring --tail=100

# Check collector metrics endpoint
kubectl exec -it <otel-pod> -n monitoring -- wget -qO- http://localhost:8888/metrics

# Verify collector configuration
kubectl get configmap otelcol-config -n monitoring -o yaml
```

### **Phase 3: Dependency Analysis**

#### **1. External Dependencies**

```bash
# Test external endpoints
kubectl run test-pod --image=curlimages/curl -it --rm -- curl -v https://api.external-service.com/health

# Check DNS resolution
kubectl run test-pod --image=busybox -it --rm -- nslookup external-service.com

# Network connectivity tests
kubectl run test-pod --image=nicolaka/netshoot -it --rm -- traceroute external-service.com
```

#### **2. Database Connectivity**

```bash
# Test DynamoDB connectivity from pods
kubectl exec -it <mimir-pod> -n monitoring -- aws dynamodb describe-table --table-name mimir-index-dev --region us-west-2

# Test S3 connectivity
kubectl exec -it <mimir-pod> -n monitoring -- aws s3 ls s3://observability-mimir-dev/ --region us-west-2
```

## 🛠️ **Common Resolution Strategies**

### **1. Resource Constraints**

#### **CPU/Memory Issues**

```yaml
# Increase resource limits
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mimir-ingester
spec:
  template:
    spec:
      containers:
        - name: ingester
          resources:
            requests:
              cpu: 500m # Increased from 100m
              memory: 1Gi # Increased from 512Mi
            limits:
              cpu: 2000m # Increased from 500m
              memory: 4Gi # Increased from 1Gi
```

#### **Storage Issues**

```bash
# Increase PVC size
kubectl patch pvc mimir-data-0 -p '{"spec":{"resources":{"requests":{"storage":"100Gi"}}}}'

# Clean up old data if needed
kubectl exec -it mimir-ingester-0 -- rm -rf /data/old-chunks/
```

### **2. Configuration Issues**

#### **Fix Mimir Configuration**

```yaml
# Common config fixes
mimir:
  config:
    ingester:
      ring:
        heartbeat_timeout: 10m # Increase if nodes are slow
    limits:
      ingestion_rate: 100000 # Increase if hitting rate limits
      ingestion_burst_size: 200000
```

#### **Fix Loki Configuration**

```yaml
loki:
  config:
    limits_config:
      ingestion_rate_mb: 100 # Increase if hitting rate limits
      ingestion_burst_size_mb: 200
      max_query_parallelism: 16 # Increase for better query performance
```

### **3. Network Issues**

#### **Service Mesh/Network Policy Fixes**

```yaml
# Allow traffic between components
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-monitoring-traffic
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/part-of: mimir
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: monitoring
  egress:
    - to: [] # Allow all egress
```

### **4. Scaling Solutions**

#### **Horizontal Pod Autoscaler**

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: mimir-ingester-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: StatefulSet
    name: mimir-ingester
  minReplicas: 3
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

## 🚨 **Emergency Procedures**

### **Circuit Breaker - Stop Ingestion**

```bash
# Temporary: Scale down ingesters to prevent data loss
kubectl scale statefulset mimir-ingester --replicas=0 -n monitoring

# Stop log ingestion if Loki is overloaded
kubectl scale deployment loki-write --replicas=0 -n monitoring
```

### **Traffic Routing**

```bash
# Route traffic away from problematic components
kubectl patch ingress mimir-ingress -p '{"spec":{"rules":[]}}'

# Use backup endpoints if available
kubectl patch service mimir-gateway -p '{"spec":{"selector":{"app":"mimir-backup"}}}'
```

### **Data Recovery**

```bash
# If data corruption is suspected
kubectl exec -it mimir-ingester-0 -- /bin/sh
# Inside pod:
curl -X POST http://localhost:8080/ingester/flush_chunks
curl -X POST http://localhost:8080/ingester/shutdown

# Restart with clean state
kubectl delete pod mimir-ingester-0
```

## 📊 **Monitoring During Incident**

### **Key Metrics to Watch**

```promql
# Error rates
rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m])

# Latency percentiles
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Resource utilization
rate(container_cpu_usage_seconds_total[5m])
container_memory_working_set_bytes / container_spec_memory_limit_bytes

# Queue depths
cortex_ingester_memory_series
loki_ingester_memory_chunks
```

### **Real-time Monitoring Commands**

```bash
# Watch error logs in real-time
kubectl logs -f -l app.kubernetes.io/name=mimir -n monitoring | grep -i error

# Monitor resource usage
watch "kubectl top pods -n monitoring --sort-by=cpu"

# Track pod restarts
kubectl get pods -n monitoring -w
```

## 📋 **Recovery Verification**

### **Success Criteria Checklist**

- [ ] Error rate below 1% for 10 minutes
- [ ] All pods in `Running` state
- [ ] Response latency back to baseline
- [ ] No resource constraints detected
- [ ] SLOs green across all services
- [ ] Ingestion pipeline flowing normally
- [ ] Query performance restored

### **Health Check Commands**

```bash
# Verify services are healthy
curl -f http://mimir-gateway:8080/-/ready
curl -f http://loki-gateway:3100/ready
curl -f http://tempo-gateway:3100/ready

# Test end-to-end functionality
kubectl run test --image=prom/prometheus --rm -it -- promtool query instant http://mimir-gateway:8080/prometheus 'up'

# Verify data ingestion is working
kubectl logs -l app=opentelemetry-collector -n monitoring --tail=10 | grep "successfully sent"
```

## 📞 **Escalation Matrix**

| **Timeframe** | **Action**                    | **Contact**        |
| ------------- | ----------------------------- | ------------------ |
| 0-15 minutes  | On-call engineer investigates | DevOps Team        |
| 15-30 minutes | Escalate to senior engineer   | Platform Team Lead |
| 30-60 minutes | Engage architecture team      | Principal Engineer |
| > 60 minutes  | Emergency response team       | Incident Commander |

## 📝 **Post-Incident Checklist**

1. **Document timeline and root cause**
2. **Update monitoring/alerting if gaps found**
3. **Review and update this runbook**
4. **Conduct blameless post-mortem**
5. **Implement preventive measures**
6. **Update disaster recovery procedures**
7. **Share learnings with broader team**

## 🎯 **Prevention Strategies**

- **Implement gradual rollouts** for configuration changes
- **Add synthetic monitoring** for early error detection
- **Set up proper resource limits** and requests
- **Regular chaos engineering** exercises
- **Automated recovery procedures** where possible
- **Comprehensive integration testing** in staging
