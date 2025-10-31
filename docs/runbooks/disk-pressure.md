# 💾 Disk Pressure Runbook

## 🚨 **Alert: Node Disk Pressure**

This runbook provides step-by-step procedures for investigating and resolving disk pressure issues in Kubernetes nodes.

## 📊 **Symptoms**

- Pods being evicted from nodes
- New pods failing to schedule
- `DiskPressure` condition on nodes
- Storage alerts firing
- Application performance degradation

## 🔍 **Investigation Steps**

### **1. Identify Affected Nodes**

```bash
# Check nodes with disk pressure
kubectl get nodes -o wide | grep -i pressure

# Get detailed node conditions
kubectl describe nodes | grep -A5 -B5 "DiskPressure"

# Check node disk usage
kubectl top nodes --sort-by=disk
```

### **2. Examine Node Disk Usage**

```bash
# SSH to affected node and check disk usage
ssh ec2-user@<node-ip>
df -h

# Check which directories are consuming space
du -sh /* | sort -hr | head -10

# Check container and image storage
docker system df
```

### **3. Identify Pod Storage Usage**

```bash
# List pods on affected node
kubectl get pods --all-namespaces --field-selector spec.nodeName=<node-name>

# Check persistent volume claims
kubectl get pvc --all-namespaces

# Examine pod storage usage
kubectl exec -it <pod-name> -n <namespace> -- df -h
```

### **4. Container Log Analysis**

```bash
# Check for large log files
kubectl logs --tail=0 --all-containers=true <pod-name> -n <namespace> | wc -l

# Find pods with large logs
for pod in $(kubectl get pods -o name); do
  echo "=== $pod ==="
  kubectl logs --tail=0 $pod 2>/dev/null | wc -l
done

# Check container runtime logs
journalctl -u kubelet --since "1 hour ago" | grep -i "disk\|space\|evict"
```

## 🛠️ **Immediate Actions**

### **Priority 1: Prevent Further Impact**

1. **Cordon the node** to prevent new pods from scheduling:

   ```bash
   kubectl cordon <node-name>
   ```

2. **Check critical workloads** and consider manual evacuation:
   ```bash
   kubectl get pods -o wide | grep <node-name> | grep -E "(prometheus|grafana|mimir|loki)"
   ```

### **Priority 2: Free Up Space**

#### **Option A: Clean Container Images**

```bash
# On the affected node
docker image prune -a --force

# Remove unused containers
docker container prune --force

# Remove unused volumes (careful!)
docker volume prune --force
```

#### **Option B: Log Rotation**

```bash
# Truncate large container logs
truncate -s 0 /var/log/containers/*.log

# Force log rotation
logrotate -f /etc/logrotate.d/docker-container
```

#### **Option C: Clean Kubernetes Cache**

```bash
# Remove completed pods
kubectl get pods --all-namespaces --field-selector=status.phase=Succeeded -o name | xargs kubectl delete

# Clean up failed pods older than 1 hour
kubectl get pods --all-namespaces --field-selector=status.phase=Failed \
  --sort-by=.status.startTime | head -n -5 | xargs kubectl delete
```

### **Priority 3: Emergency Storage Expansion**

```bash
# For EBS volumes, resize the volume (requires instance stop/start)
aws ec2 modify-volume --volume-id <volume-id> --size <new-size>

# Extend filesystem after volume resize
sudo resize2fs /dev/xvda1  # For ext4
sudo xfs_growfs /          # For xfs
```

## 🔧 **Resolution Strategies**

### **1. Temporary Solutions**

#### **Increase Node Storage**

```terraform
# Update EKS node group configuration
resource "aws_eks_node_group" "observability" {
  disk_size = 100  # Increase from current size

  # Or use larger instance types with more ephemeral storage
  instance_types = ["m5.xlarge"]  # Instead of m5.large
}
```

#### **Add Log Rotation**

```yaml
# Add to DaemonSet for log rotation
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: log-rotator
spec:
  template:
    spec:
      containers:
        - name: rotator
          image: busybox
          command: ["/bin/sh"]
          args:
            [
              "-c",
              "while true; do find /var/log/containers -name '*.log' -size +100M -exec truncate -s 50M {} \\; ; sleep 300; done",
            ]
          volumeMounts:
            - name: log-dir
              mountPath: /var/log/containers
      volumes:
        - name: log-dir
          hostPath:
            path: /var/log/containers
```

### **2. Long-term Solutions**

#### **Implement Monitoring Dashboards**

```yaml
# Grafana dashboard for disk usage monitoring
apiVersion: v1
kind: ConfigMap
metadata:
  name: disk-monitoring-dashboard
data:
  dashboard.json: |
    {
      "dashboard": {
        "title": "Node Disk Usage",
        "panels": [
          {
            "title": "Disk Usage by Node",
            "targets": [
              {
                "expr": "100 - (node_filesystem_avail_bytes / node_filesystem_size_bytes * 100)"
              }
            ]
          }
        ]
      }
    }
```

#### **Set Up Automated Cleanup**

```yaml
# CronJob for automated cleanup
apiVersion: batch/v1
kind: CronJob
metadata:
  name: disk-cleanup
spec:
  schedule: "0 2 * * *" # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: cleanup
              image: alpine:latest
              command: ["/bin/sh"]
              args:
                - -c
                - |
                  # Cleanup old container logs
                  find /var/log/containers -name "*.log" -mtime +7 -delete
                  # Docker cleanup
                  docker system prune -f --volumes
                  # Remove unused images older than 168h (7 days)
                  docker image prune -a --filter "until=168h" -f
          restartPolicy: OnFailure
```

#### **Implement Disk Usage Alerts**

```yaml
# PrometheusRule for disk pressure alerts
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: disk-pressure-alerts
spec:
  groups:
    - name: disk.pressure
      rules:
        - alert: NodeDiskPressureWarning
          expr: node_filesystem_avail_bytes / node_filesystem_size_bytes < 0.15
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "Node {{ $labels.instance }} disk usage above 85%"

        - alert: NodeDiskPressureCritical
          expr: node_filesystem_avail_bytes / node_filesystem_size_bytes < 0.10
          for: 2m
          labels:
            severity: critical
          annotations:
            summary: "Node {{ $labels.instance }} disk usage above 90%"
```

## 📋 **Prevention Checklist**

- [ ] **Monitor disk usage trends** via Grafana dashboards
- [ ] **Set up proactive alerts** at 80% disk usage
- [ ] **Implement log rotation** for all applications
- [ ] **Regular cleanup policies** for container images and logs
- [ ] **Right-size node storage** based on usage patterns
- [ ] **Use persistent volumes** for stateful workloads
- [ ] **Implement resource limits** to prevent runaway processes
- [ ] **Regular capacity planning** reviews

## 🎯 **Success Criteria**

✅ Node disk usage below 80%
✅ No pods in evicted state
✅ Node condition shows `Ready`
✅ New pods can schedule successfully
✅ Applications running normally

## 📞 **Escalation**

If disk pressure persists after following this runbook:

1. **Level 2**: Infrastructure team for node replacement/scaling
2. **Level 3**: Cloud architecture team for storage strategy review
3. **Emergency**: If critical workloads affected, consider emergency maintenance window

## 📝 **Post-Incident Actions**

1. Document root cause and timeline
2. Update monitoring thresholds if needed
3. Review disk sizing for affected node groups
4. Update this runbook based on lessons learned
5. Conduct post-mortem with team if critical services were impacted
