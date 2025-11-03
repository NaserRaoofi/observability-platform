# GitOps Configuration

This directory contains the GitOps configuration for the Observability Platform deployment using ArgoCD.

## 📁 Directory Structure

```
gitops/
├── README.md                    # This file
├── applications/                # ArgoCD Applications
│   ├── observability-dev.yaml
│   ├── observability-staging.yaml
│   └── observability-prod.yaml
├── environments/                # Environment-specific configurations
│   ├── dev/                    # Development environment
│   ├── staging/                # Staging environment
│   └── prod/                   # Production environment
└── argocd/                     # ArgoCD setup and configuration
    ├── install.yaml
    ├── app-of-apps.yaml
    └── projects.yaml

```

## 🚀 Deployment Flow

1. **CI Pipeline**: Builds and pushes container image to GHCR
2. **GitOps Update**: CI updates the image tag in environment-specific files
3. **ArgoCD Sync**: ArgoCD detects changes and deploys to Kubernetes clusters
4. **Promotion**: Manual promotion between environments (dev → staging → prod)

## 🔧 Environment Configuration

### Development

- **Cluster**: Local/Development cluster
- **Image Tag**: `latest`
- **Resources**: Minimal resource allocation
- **Monitoring**: Basic monitoring enabled

### Staging

- **Cluster**: Staging cluster
- **Image Tag**: Semantic versioned tags (v1.2.3)
- **Resources**: Production-like resource allocation
- **Monitoring**: Full monitoring stack

### Production

- **Cluster**: Production cluster
- **Image Tag**: Stable semantic versioned tags
- **Resources**: Full production resource allocation
- **Monitoring**: Full monitoring with alerting

## 🛠️ Setup Instructions

### 1. Install ArgoCD

```bash
kubectl apply -f gitops/argocd/install.yaml
```

### 2. Configure ArgoCD Projects

```bash
kubectl apply -f gitops/argocd/projects.yaml
```

### 3. Deploy App of Apps

```bash
kubectl apply -f gitops/argocd/app-of-apps.yaml
```

## 🔄 CI/CD Integration

The CI pipeline automatically updates image tags in the GitOps configuration:

- **Main branch**: Updates staging and production configurations
- **Developer branch**: Updates development configuration
- **Feature branches**: No GitOps updates (validation only)

## 📊 Monitoring GitOps

- **ArgoCD UI**: Monitor deployment status and sync health
- **Kubectl**: Check application status with `kubectl get applications -n argocd`
- **Logs**: View deployment logs in ArgoCD UI or via kubectl

## 🔐 Security

- **RBAC**: Proper role-based access control for each environment
- **Secrets**: Managed via Kubernetes secrets or external secret management
- **Image Security**: Only signed and scanned images are deployed
- **Network Policies**: Proper network segmentation between environments

## 📚 References

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [GitOps Principles](https://www.gitops.tech/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
