# 🏷️ Enterprise Versioning & Tagging Strategy

## Overview

This document outlines the professional versioning and tagging strategy for the Observability Platform, designed to follow industry best practices and support enterprise deployment workflows.

## 🎯 Versioning Philosophy

### Core Principles

1. **Immutable Releases** - Every version is permanent and traceable
2. **Semantic Meaning** - Each tag type serves a specific purpose
3. **Deployment Flexibility** - Multiple tag strategies for different use cases
4. **Audit Trail** - Complete traceability from Git commit to container image

## 🏷️ Tagging Strategy

### Container Image Tags (GHCR)

| Tag Type          | Format                      | Example                                       | Use Case            | Stability    |
| ----------------- | --------------------------- | --------------------------------------------- | ------------------- | ------------ |
| **Latest**        | `latest`                    | `observability-platform:latest`               | Development/Testing | 🔄 Rolling   |
| **Semantic**      | `v{major}.{minor}.{patch}`  | `observability-platform:v1.2.15`              | Production Release  | 🔒 Stable    |
| **Calendar**      | `v{YYYY}.{MM}.{DD}.{build}` | `observability-platform:v2025.11.03.1`        | Date-based Release  | 🔒 Stable    |
| **Daily Stable**  | `v{YYYY}.{MM}.{DD}`         | `observability-platform:v2025.11.03`          | Daily Stable Build  | 🔒 Stable    |
| **Immutable SHA** | `sha-{short-sha}`           | `observability-platform:sha-a1b2c3d4`         | Exact Commit        | 🔒 Immutable |
| **Audit Trail**   | `main-{full-sha}`           | `observability-platform:main-a1b2c3d4e5f6...` | Full Audit          | 🔒 Immutable |

### Git Tags

| Tag Type             | Format                            | Example          | Trigger          | Purpose                   |
| -------------------- | --------------------------------- | ---------------- | ---------------- | ------------------------- |
| **Semantic Release** | `v{major}.{minor}.{patch}`        | `v1.2.15`        | Main branch push | Production release marker |
| **Pre-release**      | `v{major}.{minor}.{patch}-{pre}`  | `v1.3.0-rc1`     | Manual           | Release candidate         |
| **Hotfix**           | `v{major}.{minor}.{patch}+hotfix` | `v1.2.15+hotfix` | Manual           | Emergency fixes           |

## 🔄 Automated Versioning Logic

### Semantic Version Generation

```bash
# Auto-increment logic:
1. Get last semantic tag: git describe --tags --abbrev=0
2. Count commits since last tag: git rev-list --count {last_tag}..HEAD
3. Increment patch version by commit count
4. Create new semantic version: v{major}.{minor}.{patch+commits}
```

### Calendar Version Generation

```bash
# Date-based versioning:
1. Current date: YYYY.MM.DD
2. Build number: commits since midnight
3. Format: v{YYYY}.{MM}.{DD}.{build_number}
```

## 🚀 Deployment Recommendations

### Production Environment

```yaml
# Kubernetes Deployment
image: ghcr.io/naserraoofi/observability-platform:v1.2.15
# Use semantic versions for production - immutable and traceable
```

### Staging Environment

```yaml
# Kubernetes Deployment
image: ghcr.io/naserraoofi/observability-platform:v2025.11.03
# Use daily stable for staging - recent but stable
```

### Development Environment

```yaml
# Docker Compose
image: ghcr.io/naserraoofi/observability-platform:latest
# Use latest for development - always current
```

### Rollback Strategy

```yaml
# Emergency rollback to specific commit
image: ghcr.io/naserraoofi/observability-platform:sha-a1b2c3d4
# Use SHA tags for exact commit rollback
```

## 📋 Version Management Workflow

### Feature Development

1. **Feature Branch** → CI builds test image (not published)
2. **Developer Branch** → CI builds test image (not published)
3. **Pull Request** → Full CI validation (no publishing)

### Production Release

1. **Merge to Main** → Triggers full CI pipeline
2. **Version Generation** → Auto-calculates all version tags
3. **Container Build** → Creates production container image
4. **Multi-tag Push** → Publishes all version variants to GHCR
5. **Git Tagging** → Creates semantic git tag for release
6. **Deployment Ready** → Images available for GitOps deployment

### Hotfix Process

```bash
# Emergency hotfix workflow:
1. Create hotfix branch from production tag
2. Apply minimal fix
3. Create hotfix tag: v1.2.15+hotfix
4. Deploy directly to production
5. Merge back to main and developer
```

## 🔍 Traceability Matrix

### From Git Commit to Production

```
Git Commit (abc123def456)
    ↓
Git Tag (v1.2.15)
    ↓
Container Image (observability-platform:v1.2.15)
    ↓
Kubernetes Deployment (production-cluster)
    ↓
Service Running (observability-platform-v1-2-15)
```

### Audit Questions & Answers

- **"What code is running in production?"** → Check image tag, trace to git commit
- **"When was this version deployed?"** → Check git tag timestamp and CI logs
- **"What changed in this release?"** → Compare git tags: `git log v1.2.14..v1.2.15`
- **"How do I rollback?"** → Deploy previous semantic version or specific SHA

## 🛡️ Security & Compliance

### Image Scanning

- **Every main branch push** → Full security scan with Trivy
- **SBOM Generation** → Software Bill of Materials for compliance
- **Vulnerability Tracking** → Tagged images include security metadata

### Audit Requirements

- **Immutable Tags** → SHA-based tags never change
- **Complete Lineage** → Git commit → CI build → Container image → Deployment
- **Retention Policy** → All versions kept for audit trail
- **Access Control** → GHCR permissions managed via GitHub

## 📊 Version Analytics

### Success Metrics

- **Build Success Rate** → CI pipeline reliability
- **Deployment Frequency** → Release velocity
- **Lead Time** → Commit to deployment time
- **Rollback Rate** → Deployment quality indicator

### Monitoring Dashboards

- **Version Deployment Timeline** → Visual release history
- **Image Size Trends** → Container optimization tracking
- **Security Score Evolution** → Vulnerability trend analysis
- **Build Performance** → CI pipeline optimization metrics

## 🔧 Tools & Integration

### Required Tools

- **Git** → Source control and tagging
- **Docker/Buildx** → Container image building
- **GitHub Actions** → CI/CD automation
- **GHCR** → Container registry
- **Trivy** → Security scanning
- **Syft** → SBOM generation

### Integration Points

- **ArgoCD/Flux** → GitOps deployment automation
- **Kubernetes** → Container orchestration
- **Monitoring** → Prometheus/Grafana observability
- **Alerting** → Deployment success/failure notifications

---

## 🚀 Quick Reference

### Most Common Commands

```bash
# Check current production version
kubectl get deployment -o jsonpath='{.spec.template.spec.containers[0].image}'

# List all available versions
docker images ghcr.io/naserraoofi/observability-platform

# Deploy specific version
kubectl set image deployment/observability-platform app=ghcr.io/naserraoofi/observability-platform:v1.2.15

# Emergency rollback to previous version
kubectl rollout undo deployment/observability-platform
```

### Best Practices Summary

1. ✅ **Use semantic versions** for production deployments
2. ✅ **Use daily stable** for staging environments
3. ✅ **Use latest** only for development
4. ✅ **Always tag major releases** manually for important milestones
5. ✅ **Keep audit trail** with SHA-based tags
6. ✅ **Test rollback procedures** regularly
7. ✅ **Monitor version deployment success**
