# Utility Scripts

This directory contains utility scripts for managing the observability platform.

## 📁 Available Scripts

### **🧹 `cleanup.sh`** - Platform Teardown

```bash
./scripts/cleanup.sh [environment]
```

**Purpose:** Clean teardown of the entire observability platform

- Removes Kubernetes resources via Kustomize
- Destroys Helm releases via Helmfile
- Cleans up namespaces
- Stops any running port forwards

**Usage:**

```bash
# Clean up dev environment (default)
./scripts/cleanup.sh

# Clean up specific environment
./scripts/cleanup.sh prod
```

### **🔗 `port-forward.sh`** - Local Service Access

```bash
./scripts/port-forward.sh [environment]
```

**Purpose:** Set up local port forwarding for easy service access

- Grafana: `localhost:3000`
- Mimir: `localhost:8080`
- Loki: `localhost:3100`
- Tempo: `localhost:16686`
- OTel Collector: `localhost:4317`

**Usage:**

```bash
# Start port forwarding for dev environment
./scripts/port-forward.sh

# Start port forwarding for specific environment
./scripts/port-forward.sh prod

# Stop all port forwards
pkill -f "kubectl port-forward"
```

## 🗑️ Removed Scripts

The following scripts were **removed as redundant** because their functionality is now handled by modern tooling:

### **~~`add-helm-repos.sh`~~ - REMOVED** ❌

- **Replaced by:** Helmfile automatically manages repositories
- **Reason:** `helmfile.yaml` contains repository definitions and handles `helm repo add/update` automatically

### **~~`bootstrap.sh`~~ - REMOVED** ❌

- **Replaced by:** Terraform modules in `terraform/modules/`
- **Reason:** Infrastructure creation (S3, DynamoDB, KMS) is now declaratively managed by Terraform

## 🚀 Modern Deployment Workflow

Instead of individual scripts, use the integrated approach:

```bash
# 1. Deploy infrastructure
cd terraform/envs/dev
terraform apply

# 2. Deploy platform services
cd ../../..
helmfile sync                     # Deploys operators and services
kubectl apply -k k8s/base/grafana/  # Deploys Grafana instance + dashboards

# 3. Access services locally
./scripts/port-forward.sh

# 4. Clean up when done
./scripts/cleanup.sh
```

This approach provides **better integration**, **dependency management**, and **declarative infrastructure**.
