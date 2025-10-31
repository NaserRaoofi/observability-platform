# ⏱️ High Latency Runbook

## 🚨 **Alert: High Response Latency Detected**

This runbook provides systematic procedures for investigating and resolving high latency issues across the observability platform and monitored applications.

## 📊 **Alert Definitions**

```yaml
# Latency thresholds
Warning: P95 > 5 seconds for 5 minutes
Critical: P95 > 10 seconds for 2 minutes
P0: P50 > 10 seconds for 1 minute
```

## 🔍 **Initial Assessment (First 5 Minutes)**

### **1. Scope Identification**

```bash
# Quick health check of all services
kubectl get pods -n monitoring -o wide
kubectl top pods -n monitoring --sort-by=memory

# Check service response times
time curl -s http://mimir-gateway:8080/-/ready
time curl -s http://loki-gateway:3100/ready
time curl -s http://grafana:3000/api/health
```

### **2. Latency Hotspot Analysis**

#### **Check Grafana Dashboards**

1. **Latency Overview Dashboard** - P50, P95, P99 percentiles
2. **Service Map** - Identify bottlenecks in request flow
3. **Infrastructure Metrics** - CPU, Memory, Disk I/O

#### **Quick Metrics Query**

```bash
# Port forward to Mimir for quick queries
kubectl port-forward svc/mimir-gateway 8080:8080 &

# Check current latency percentiles
curl -G "http://localhost:8080/prometheus/api/v1/query" \
  --data-urlencode 'query=histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))'

# Check request rate
curl -G "http://localhost:8080/prometheus/api/v1/query" \
  --data-urlencode 'query=rate(http_requests_total[5m])'
```

## 🎯 **Systematic Investigation**

### **Phase 1: Infrastructure Bottlenecks**

#### **1. Resource Utilization Analysis**

```bash
# Check CPU usage across nodes
kubectl top nodes --sort-by=cpu

# Memory pressure indicators
kubectl top pods -n monitoring --sort-by=memory
kubectl describe nodes | grep -A5 "Allocated resources"

# Disk I/O bottlenecks
kubectl exec -it <pod-name> -n monitoring -- iostat -x 1 5

# Network latency between pods
kubectl exec -it <pod-1> -n monitoring -- ping <pod-2-ip>
```

#### **2. Kubernetes Resource Constraints**

```bash
# Check for resource throttling
kubectl describe pods -n monitoring | grep -A5 -B5 "throttl"

# Look for pending pods due to resource constraints
kubectl get pods -n monitoring | grep Pending
kubectl describe pods <pending-pod> -n monitoring

# Check HPA status if configured
kubectl get hpa -n monitoring
kubectl describe hpa <hpa-name> -n monitoring
```

### **Phase 2: Application Performance Analysis**

#### **1. Mimir Performance Investigation**

```bash
# Check Mimir component latencies
kubectl logs -l app.kubernetes.io/component=gateway -n monitoring --tail=100 | grep -i "latency\|slow\|timeout"

# Ingester performance
kubectl exec -it mimir-ingester-0 -n monitoring -- curl -s http://localhost:8080/metrics | grep -E "(cortex_ingester_.*duration|cortex_ingester_.*latency)"

# Querier performance
kubectl logs -l app.kubernetes.io/component=querier -n monitoring --tail=50 | grep -E "(query.*took|slow.*query)"

# Check for hot sharding or uneven load distribution
kubectl exec -it mimir-ingester-0 -n monitoring -- curl -s http://localhost:8080/ingester/ring
```

#### **2. Loki Performance Investigation**

```bash
# Check Loki write path latency
kubectl logs -l app.kubernetes.io/component=write -n monitoring --tail=100 | grep -E "(took|duration|latency)"

# Read path performance
kubectl logs -l app.kubernetes.io/component=read -n monitoring --tail=50 | grep -E "(query.*took|slow)"

# Check chunk cache performance
kubectl exec -it loki-read-0 -n monitoring -- curl -s http://localhost:3100/metrics | grep loki_chunk_cache

# Index query performance
kubectl exec -it loki-read-0 -n monitoring -- curl -s http://localhost:3100/metrics | grep loki_index_request_duration
```

#### **3. Storage Backend Performance**

```bash
# DynamoDB performance metrics (from AWS CLI or CloudWatch)
aws dynamodb describe-table --table-name mimir-index-dev --query 'Table.TableStatus'

# Check DynamoDB throttling
aws logs filter-log-events --log-group-name /aws/dynamodb/table/mimir-index-dev \
  --filter-pattern "throttl" --start-time $(date -d '1 hour ago' +%s)000

# S3 performance analysis
aws s3api head-object --bucket observability-mimir-dev --key test-object 2>&1 | grep -i "time\|slow"

# Check S3 request metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/S3 \
  --metric-name AllRequests \
  --dimensions Name=BucketName,Value=observability-mimir-dev \
  --start-time $(date -d '1 hour ago' -u +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

### **Phase 3: Network and Connectivity**

#### **1. Network Latency Analysis**

```bash
# Inter-pod network latency
kubectl run network-test --image=nicolaka/netshoot -it --rm -- \
  ping -c 10 <target-pod-ip>

# DNS resolution performance
kubectl run dns-test --image=busybox -it --rm -- \
  time nslookup mimir-gateway.monitoring.svc.cluster.local

# Service mesh latency (if using Istio/Linkerd)
kubectl exec -it <pod-with-sidecar> -c istio-proxy -- \
  curl -s http://localhost:15000/stats | grep -i latency
```

#### **2. External Dependencies**

```bash
# AWS API latency
time aws sts get-caller-identity --region us-west-2

# External service dependencies
kubectl run curl-test --image=curlimages/curl -it --rm -- \
  time curl -s https://external-api.example.com/health
```

## 🛠️ **Performance Optimization Strategies**

### **1. Resource Scaling**

#### **Vertical Scaling (Increase Resources)**

```yaml
# Increase CPU/Memory for latency-sensitive components
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mimir-querier
spec:
  template:
    spec:
      containers:
        - name: querier
          resources:
            requests:
              cpu: 1000m # Increased from 500m
              memory: 2Gi # Increased from 1Gi
            limits:
              cpu: 4000m # Increased from 2000m
              memory: 8Gi # Increased from 4Gi
```

#### **Horizontal Scaling (More Replicas)**

```bash
# Scale out read-heavy components
kubectl scale deployment mimir-querier --replicas=5 -n monitoring
kubectl scale deployment loki-read --replicas=3 -n monitoring

# Auto-scaling configuration
cat <<EOF | kubectl apply -f -
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: mimir-querier-hpa
  namespace: monitoring
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: mimir-querier
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Pods
    pods:
      metric:
        name: http_request_duration_seconds_bucket
      target:
        type: AverageValue
        averageValue: 500m
EOF
```

### **2. Configuration Optimization**

#### **Mimir Performance Tuning**

```yaml
mimir:
  config:
    # Query performance
    querier:
      max_concurrent: 20 # Increase concurrent queries
      timeout: 2m # Reduce timeout for faster failure

    # Ingester optimization
    ingester:
      max_transfer_retries: 0 # Disable retries for faster startup
      ring:
        heartbeat_period: 5s # Faster health checks

    # Cache optimization
    frontend:
      results_cache:
        cache:
          memcached:
            timeout: 500ms # Aggressive cache timeout

    # Compactor efficiency
    compactor:
      deletion_delay: 2h # Faster cleanup
      max_closing_blocks_concurrency: 4
```

#### **Loki Performance Tuning**

```yaml
loki:
  config:
    # Query performance
    query_scheduler:
      max_outstanding_requests_per_tenant: 100

    # Ingester optimization
    ingester:
      chunk_target_size: 1572864 # 1.5MB chunks for better performance
      max_chunk_age: 2h # Smaller chunks, faster queries

    # Cache configuration
    chunk_store_config:
      cache_lookups_older_than: 0s

    # Limits for performance
    limits_config:
      max_query_parallelism: 32 # Increase parallelism
      max_concurrent_tail_requests: 20
      max_query_series: 10000 # Increase if needed
```

### **3. Caching Strategies**

#### **Enable Query Result Caching**

```yaml
# Mimir query result cache
mimir:
  config:
    query_range:
      results_cache:
        cache:
          embedded_cache:
            enabled: true
            max_size_mb: 1024
            ttl: 1h

# Loki query result cache
loki:
  config:
    query_range:
      results_cache:
        cache:
          embedded_cache:
            enabled: true
            max_size_mb: 512
            ttl: 30m
```

#### **Chunk Store Caching**

```yaml
# Enhanced chunk caching for Loki
loki:
  config:
    chunk_store_config:
      chunk_cache_config:
        embedded_cache:
          enabled: true
          max_size_mb: 2048
          ttl: 24h

      write_dedupe_cache_config:
        embedded_cache:
          enabled: true
          max_size_mb: 256
          ttl: 1h
```

### **4. Storage Optimization**

#### **DynamoDB Performance Improvements**

```terraform
# Increase DynamoDB provisioned capacity for predictable workloads
resource "aws_dynamodb_table" "mimir_index" {
  billing_mode = "PROVISIONED"

  read_capacity  = 100  # Increase based on query patterns
  write_capacity = 50   # Increase based on ingestion rate

  # Add Global Secondary Index for common query patterns
  global_secondary_index {
    name            = "timestamp-index"
    hash_key        = "timestamp_day"
    range_key       = "timestamp_hour"
    read_capacity   = 50
    write_capacity  = 25
  }
}
```

#### **S3 Performance Optimization**

```terraform
# Use S3 Transfer Acceleration for faster uploads
resource "aws_s3_bucket_accelerate_configuration" "mimir_bucket" {
  bucket = aws_s3_bucket.mimir.id
  status = "Enabled"
}

# Optimize multipart upload settings
resource "aws_s3_bucket_lifecycle_configuration" "mimir_lifecycle" {
  bucket = aws_s3_bucket.mimir.id

  rule {
    id     = "multipart_cleanup"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}
```

## 🚨 **Emergency Latency Mitigation**

### **1. Circuit Breaker Activation**

```bash
# Temporarily reduce query complexity
kubectl patch configmap mimir-config -n monitoring --type merge -p '{
  "data": {
    "config.yaml": "limits:\n  max_query_lookback: 1h\n  max_query_parallelism: 4\n  max_query_series: 1000"
  }
}'

# Restart queriers to pick up new config
kubectl rollout restart deployment/mimir-querier -n monitoring
```

### **2. Load Shedding**

```bash
# Scale down non-critical components temporarily
kubectl scale deployment mimir-compactor --replicas=0 -n monitoring
kubectl scale deployment loki-compactor --replicas=0 -n monitoring

# Prioritize read path over write path
kubectl scale deployment mimir-distributor --replicas=2 -n monitoring
kubectl scale deployment mimir-querier --replicas=8 -n monitoring
```

### **3. Traffic Routing**

```yaml
# Route traffic to faster/less loaded instances
apiVersion: v1
kind: Service
metadata:
  name: mimir-gateway-fast
spec:
  selector:
    app.kubernetes.io/name: mimir
    app.kubernetes.io/component: gateway
    performance-tier: fast # Only select high-performance pods
  ports:
    - port: 8080
      targetPort: 8080
```

## 📊 **Real-Time Monitoring**

### **Key Latency Metrics**

```bash
# Monitor latency in real-time
watch "kubectl exec -it mimir-querier-0 -n monitoring -- curl -s http://localhost:8080/metrics | grep -E 'cortex_request_duration_seconds_(bucket|sum|count)'"

# Track query performance
kubectl logs -f mimir-querier-0 -n monitoring | grep -E "(query.*took|duration:|latency:)"

# Monitor resource utilization
watch "kubectl top pods -n monitoring --sort-by=cpu | head -10"
```

### **Performance Benchmarking**

```bash
# Benchmark query performance
kubectl run perf-test --image=prom/prometheus -it --rm -- \
  promtool query instant http://mimir-gateway:8080/prometheus \
  'histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))'

# Load test with specific queries
kubectl run load-test --image=grafana/k6 -it --rm -- \
  run --vus 10 --duration 60s - <<'EOF'
import http from 'k6/http';
import { check } from 'k6';

export default function() {
  const response = http.get('http://mimir-gateway:8080/prometheus/api/v1/query?query=up');
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 5000ms': (r) => r.timings.duration < 5000,
  });
}
EOF
```

## 📋 **Recovery Verification**

### **Performance Benchmarks**

- [ ] P95 latency < 2 seconds
- [ ] P99 latency < 5 seconds
- [ ] Query success rate > 99%
- [ ] No resource throttling detected
- [ ] All components responding within SLA

### **Health Check Script**

```bash
#!/bin/bash
# comprehensive-health-check.sh

echo "=== Latency Health Check ==="

# Test query latency
echo "Testing Mimir query latency..."
time kubectl exec -it mimir-querier-0 -n monitoring -- \
  curl -s "http://localhost:8080/prometheus/api/v1/query?query=up" > /dev/null

echo "Testing Loki query latency..."
time kubectl exec -it loki-read-0 -n monitoring -- \
  curl -s "http://localhost:3100/loki/api/v1/query?query={job=\"prometheus\"}" > /dev/null

# Check resource utilization
echo "Checking resource utilization..."
kubectl top pods -n monitoring --sort-by=cpu | head -5
kubectl top pods -n monitoring --sort-by=memory | head -5

# Verify no errors in logs
echo "Checking for recent errors..."
kubectl logs --tail=100 -l app.kubernetes.io/name=mimir -n monitoring | grep -i "error\|timeout\|slow" | tail -5

echo "Health check complete!"
```

## 📞 **Escalation Path**

| **P95 Latency** | **Duration** | **Action**                 | **Contact**        |
| --------------- | ------------ | -------------------------- | ------------------ |
| > 5s            | 0-10 min     | On-call investigation      | Platform Engineer  |
| > 10s           | 10-20 min    | Senior engineer engagement | Lead SRE           |
| > 20s           | 20-30 min    | Architecture team involved | Principal Engineer |
| > 30s           | > 30 min     | Emergency response         | Incident Commander |

## 📝 **Post-Incident Analysis**

### **Performance Baseline Documentation**

1. **Record normal latency patterns** for comparison
2. **Update performance budgets** based on findings
3. **Document optimization changes** made during incident
4. **Review and update monitoring** thresholds

### **Preventive Measures**

```yaml
# Implement latency SLOs
apiVersion: sloth.slok.dev/v1
kind: PrometheusServiceLevel
metadata:
  name: mimir-latency-slo
spec:
  service: mimir
  labels:
    team: platform
  slos:
    - name: query-latency
      objective: 95
      description: 95% of queries should complete within 2 seconds
      sli:
        events:
          error_query: histogram_quantile(0.95, rate(cortex_request_duration_seconds_bucket[5m])) > 2
          total_query: rate(cortex_request_duration_seconds_count[5m])
      alerting:
        name: MimirHighLatency
        labels:
          severity: critical
        annotations:
          summary: Mimir query latency SLO violation
```

## 🎯 **Performance Optimization Roadmap**

### **Short-term (1-2 weeks)**

- [ ] Implement query result caching
- [ ] Optimize resource allocations
- [ ] Add latency-based alerting
- [ ] Enable HPA for query components

### **Medium-term (1-2 months)**

- [ ] Implement query parallelization
- [ ] Add read replicas for hot data
- [ ] Optimize storage layer configuration
- [ ] Implement intelligent load balancing

### **Long-term (3-6 months)**

- [ ] Multi-region deployment for lower latency
- [ ] Advanced caching strategies (CDN, edge caching)
- [ ] Query optimization engine
- [ ] Predictive auto-scaling based on patterns
