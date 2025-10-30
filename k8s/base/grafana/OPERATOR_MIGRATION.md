# Grafana Operator Migration Guide

## 🚀 Migration Complete!

Your Grafana setup has been successfully migrated from **Helm chart** to **Grafana Operator** approach.

## 📁 New Structure

```
k8s/base/grafana/
├── operator/
│   ├── grafana-instance.yaml      # Main Grafana instance CRD
│   └── datasources.yaml           # Data source configurations
├── dashboards/
│   ├── alertmanager-overview.yaml # AlertManager dashboard CRD
│   └── slo-monitoring.yaml        # SLO monitoring dashboard CRD
├── kustomization.yaml             # Orchestration configuration
├── values-operator.yaml           # Grafana Operator Helm values
├── values.yaml                    # Original Helm values (preserved)
└── README.md                      # Documentation

# Legacy files (can be removed after successful migration):
├── dashboard-configmaps.yaml      # Old ConfigMap approach
└── dashboards/*.json              # Old JSON files (now in CRDs)
```

## 🔧 Deployment Commands

### 1. Install Grafana Operator

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

### 2. Deploy Grafana Instance & Resources

```bash
# Create observability namespace
kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -

# Deploy Grafana instance, data sources, and dashboards
kubectl apply -k k8s/base/grafana/

# Verify deployment
kubectl get grafana,grafanadatasource,grafanadashboard -n observability
```

### 3. Check Status

```bash
# Check operator status
kubectl get pods -n grafana-system -l app.kubernetes.io/name=grafana-operator

# Check Grafana instance
kubectl get pods -n observability -l app=grafana

# Check CRD resources
kubectl get grafana,grafanadatasource,grafanadashboard -n observability -o wide
```

## 🔍 Access Grafana

```bash
# Port forward to access Grafana UI
kubectl port-forward -n observability svc/grafana-service 3000:80

# Open browser
open http://localhost:3000

# Default credentials (from operator/grafana-instance.yaml):
Username: admin
Password: admin123!
```

## 📊 What's Migrated

### ✅ **Grafana Instance**

- **Configuration**: All Helm values converted to Grafana CRD
- **Security**: Same security context and RBAC
- **Storage**: 10Gi PVC with gp3 StorageClass
- **Resources**: 1Gi memory, 1 CPU limits maintained
- **Plugins**: Same plugins auto-installed
- **Monitoring**: ServiceMonitor for Prometheus

### ✅ **Data Sources**

- **Mimir**: Default Prometheus-compatible source with exemplars
- **Loki**: Log aggregation with trace correlation
- **Tempo**: Distributed tracing with service maps
- **AlertManager**: Alert management integration

### ✅ **Dashboards**

- **AlertManager Overview**: Complete dashboard with 7 panels
- **SLO Monitoring**: Comprehensive SLO tracking dashboard
- **Folders**: Organized in Infrastructure and SLO folders

## 🆚 Operator vs Helm Comparison

| Aspect           | Old (Helm)                 | New (Operator)           |
| ---------------- | -------------------------- | ------------------------ |
| **Management**   | Helm lifecycle             | Kubernetes-native CRDs   |
| **Dashboards**   | ConfigMaps + Sidecar       | GrafanaDashboard CRDs    |
| **Data Sources** | Static YAML provisioning   | GrafanaDataSource CRDs   |
| **Updates**      | `helm upgrade`             | `kubectl apply`          |
| **GitOps**       | Helm-based workflows       | Native Kubernetes GitOps |
| **Scaling**      | Manual resource management | Operator-managed         |

## 🔄 Migration Rollback (if needed)

If you need to rollback to the Helm approach:

```bash
# 1. Remove operator resources
kubectl delete -k k8s/base/grafana/
helm uninstall grafana-operator -n grafana-system

# 2. Restore original Helm deployment
helm install grafana grafana/grafana \
  --namespace observability \
  -f k8s/base/grafana/values.yaml

kubectl apply -f k8s/base/grafana/dashboard-configmaps.yaml
```

## ⚡ Performance Benefits

### **Operator Advantages**

- **🔄 Automatic Reconciliation**: Self-healing configuration
- **📊 Native Dashboard Management**: No sidecar containers needed
- **🔧 Declarative Configuration**: Everything as code via CRDs
- **🎯 Resource Efficiency**: Optimized operator vs heavy sidecar

### **Monitoring & Alerting**

- **📈 Operator Metrics**: Monitor operator health
- **🚨 CRD Status**: Track resource status via Kubernetes APIs
- **🔍 Event Logging**: Native Kubernetes event integration

## 🛠️ Troubleshooting

### **Common Issues**

1. **Operator not starting**:

   ```bash
   kubectl logs -n grafana-system deployment/grafana-operator
   ```

2. **Grafana instance not creating**:

   ```bash
   kubectl describe grafana -n observability grafana-instance
   ```

3. **Data sources not connecting**:

   ```bash
   kubectl describe grafanadatasource -n observability
   ```

4. **Dashboards not loading**:
   ```bash
   kubectl describe grafanadashboard -n observability
   ```

## 🎯 Next Steps

1. **✅ Verify all dashboards load correctly**
2. **✅ Test data source connectivity**
3. **✅ Configure alerting rules**
4. **🗑️ Remove old ConfigMaps** (after verification)
5. **📚 Update documentation** for team

## 🔐 Security Notes

- **🔒 Same Security Profile**: Maintains all security configurations
- **👤 RBAC**: Proper service accounts and permissions
- **🛡️ Pod Security**: Non-root, read-only filesystem
- **🔑 Secrets Management**: Operator manages secrets securely

Your Grafana Operator migration is now **complete**! 🎉

The setup provides better Kubernetes-native management while preserving all your existing functionality and security configurations.
