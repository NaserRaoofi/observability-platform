# GitOps Setup Guide

## 🎯 **Quick Setup Instructions**

### **1. Create GitOps Repository**

```bash
# Create the GitOps repository
gh repo create observability-gitops --private --description "GitOps repository for observability platform deployments"

# Clone and setup structure
git clone https://github.com/NaserRaoofi/observability-gitops.git
cd observability-gitops

# Create directory structure
mkdir -p {environments/{staging,production},base,argocd}
```

### **2. Setup GitHub Secrets**

Add these secrets to the **observability-platform** repository:

```
GITOPS_PAT=<github_personal_access_token>
```

### **3. Install ArgoCD**

```bash
# Install ArgoCD in your cluster
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### **4. Current CI/CD Flow**

#### **✅ What Works Now:**

1. **Developer pushes to `developer` branch**
   - ✅ Full CI validation (linting, security, testing)
   - ✅ Container build and validation
   - ❌ **NO registry push** (correct behavior)

2. **Manager merges PR to `main` branch**
   - ✅ Full CI validation
   - ✅ Container build and push to registry
   - ✅ Security scanning and SBOM generation
   - ✅ Build attestation
   - ✅ **Ready for GitOps pickup**

#### **🔄 What Happens Next (GitOps):**

1. **ArgoCD monitors GitOps repository**
2. **Detects new image in registry**
3. **Updates Kubernetes manifests**
4. **Deploys to staging automatically**
5. **Manual approval for production**

## 🚀 **Commands to Complete Setup**

```bash
# 1. Create GitHub PAT with repo permissions
gh auth token

# 2. Add secret to current repository
gh secret set GITOPS_PAT --body "your_github_pat_here"

# 3. Create GitOps repository structure
gh repo create observability-gitops --private
git clone https://github.com/NaserRaoofi/observability-gitops.git
cd observability-gitops

# 4. Setup basic GitOps structure
cat << 'EOF' > environments/staging/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- ../../base
images:
- name: observability-app
  newName: ghcr.io/naserraoofi/observability-platform
  newTag: latest
EOF

# 5. Commit and push GitOps structure
git add .
git commit -m "Initial GitOps structure"
git push origin main
```

## 📋 **Verification Steps**

1. **Test the CI pipeline**:

   ```bash
   # Push to developer branch - should validate but not deploy
   git checkout -b test-feature
   echo "test" > test.txt
   git add . && git commit -m "test: CI validation"
   git push origin test-feature
   ```

2. **Test the CD pipeline**:

   ```bash
   # Create PR and merge to main - should build and push
   gh pr create --title "Test deployment" --body "Testing full pipeline"
   gh pr merge --merge
   ```

3. **Verify container registry**:
   ```bash
   # Check if image was pushed
   docker pull ghcr.io/naserraoofi/observability-platform:latest
   ```

## 🔧 **Current Status**

✅ **CI Pipeline**: Complete enterprise-grade validation
✅ **Container Publishing**: Secure build and push to registry
✅ **GitOps Integration**: Repository dispatch trigger ready
🔄 **GitOps Repository**: Needs to be created
🔄 **ArgoCD Setup**: Needs cluster installation
🔄 **Environment Configs**: Needs GitOps manifests

The current setup follows **Netflix/Spotify-style GitOps** where:

- **This repository** handles CI and publishes containers
- **GitOps repository** handles CD and deployments
- **ArgoCD** orchestrates the actual deployments

This separation provides maximum security and operational control! 🎯
