# Enterprise Observability Platform

Production-ready, cloud-native observability platform built with professional tooling and best practices.

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   APPLICATIONS  │    │  OTEL COLLECTOR │    │    BACKENDS     │
│                 │    │                 │    │                 │
│ • OTLP          │───▶│ Agent (DaemonSet│───▶│ Mimir (Metrics) │
│ • Jaeger        │    │ Gateway (Deploy)│    │ Loki (Logs)     │
│ • Zipkin        │    │ + 6 Exporters   │    │ Tempo (Traces)  │
│ • Prometheus    │    │ + Unified Proc. │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                       ┌─────────────────┐
                       │   SLI/SLO       │
                       │   MONITORING    │
                       │                 │
                       │ Sloth + 23 SLOs │
                       │ Error Budget    │
                       │ Burn Rate Alert │
                       └─────────────────┘
```

## Components

### **Unified Telemetry Collection**

- **OpenTelemetry Collector**: Agent + Gateway deployment pattern
- **Multi-Protocol Support**: OTLP, Jaeger, Zipkin, Prometheus
- **Advanced Processing**: Sampling, correlation, transformation
- **6 Specialized Exporters**: Node, KSM, Blackbox, NGINX, Redis, CloudWatch

### **Three-Pillar Storage**

- **Mimir**: Long-term metrics storage with S3 + DynamoDB
- **Loki**: Log aggregation and search
- **Tempo**: Distributed tracing with correlation

### **SRE & Monitoring**

- **Sloth**: SLI/SLO operator with 21 comprehensive SLOs
- **Professional Tooling**: Official Helm charts, GitOps-ready
- **AWS Integration**: S3, DynamoDB, IRSA, KMS encryption

## Key Features

✅ **Enterprise Architecture**: Production-ready with HA, scaling, security
✅ **Unified Collection**: Single telemetry pipeline for all signals
✅ **Cloud Integration**: Native AWS S3/DynamoDB with proper IAM
✅ **SLO-Driven**: Comprehensive error budget and burn rate monitoring
✅ **Professional Tooling**: Official Helm charts, no custom resources
✅ **GitOps Ready**: Declarative deployment with Helmfile

## 🚀 Quick Start

### Complete Stack Deployment

```bash
# 1. Deploy infrastructure
cd terraform/envs/dev
terraform init && terraform apply

# 2. Deploy platform services
cd ../../../
helmfile sync

# 3. Deploy Grafana + dashboards
kubectl apply -k k8s/base/grafana/

# 4. Access services locally
./scripts/port-forward.sh
```

### Access Points

- **Grafana**: `localhost:3000` (admin/admin)
- **Mimir**: `localhost:8080/prometheus`
- **Loki**: `localhost:3100`
- **Tempo**: `localhost:16686`
- **OTel Gateway**: `localhost:4317`

## 📊 Monitoring & SLOs

### Service Level Objectives (7 categories)

- **Mimir**: Availability 99.9%, Latency P99 <1s, Ingestion 99.5%
- **Loki**: Query success 99%, Ingestion success 99.5%, Latency P95 <5s
- **Tempo**: Query success 99%, Ingestion success 99.5%, Latency P95 <2s
- **OTel Collector**: Processing success 99.9%, Export success 99.8%
- **Infrastructure**: Node availability 99.5%, Storage performance 99%
- **Prometheus Agent**: Scrape success 99.5%, Remote write 99.9%

### Dashboards (7 organized dashboards)

```
📁 Infrastructure/
  • Kubernetes Cluster Overview
  • AlertManager Overview

📁 Observability Platform/
  • OpenTelemetry Collector
  • Mimir Metrics Storage
  • Loki Log Storage
  • Tempo Trace Storage

📁 Reliability/
  • SLO Monitoring
```

## 🔧 Configuration

### Terraform + Helm Integration

**Infrastructure** (Terraform):

- S3 buckets with lifecycle policies
- DynamoDB tables for indexing
- IAM roles with IRSA
- KMS encryption keys

**Platform** (Helmfile + Kustomize):

- OpenTelemetry Collector (agent + gateway)
- Mimir, Loki, Tempo backends
- Grafana Operator + dashboards
- 6 specialized exporters

### Template System

Dynamic configuration from Terraform outputs:

```bash
# Templates are populated during deployment
values.template.yaml → values.generated.yaml
${aws_region} → us-west-2
${mimir_s3_bucket_name} → observability-dev-mimir
${kms_key_id} → arn:aws:kms:...
```

## 🗂️ Project Structure

```
observability-platform/
├── terraform/               # Infrastructure as Code
│   ├── modules/             # Reusable modules (s3-kms, iam, dynamodb)
│   └── envs/               # Environment configs (dev, prod)
├── k8s/base/               # Kubernetes manifests
│   ├── grafana/            # Grafana Operator + dashboards
│   ├── otel-collector/     # Telemetry collection
│   └── exporters/          # Specialized metric exporters
├── helmfile.yaml           # Declarative Helm deployment
├── deploy.sh              # Automated deployment script
└── scripts/               # Utility scripts (cleanup, port-forward)
```

## 🛠️ Operations

### Troubleshooting

```bash
# Check component health
kubectl get pods -n observability

# Verify metrics ingestion
curl "http://localhost:8080/prometheus/api/v1/query?query=up"

# Check SLO status
kubectl get prometheusrule -n observability

# View logs
kubectl logs -n observability -l app.kubernetes.io/name=mimir
```

### Cleanup

```bash
# Remove entire platform
./scripts/cleanup.sh

# Remove infrastructure
cd terraform/envs/dev && terraform destroy
```

## 📚 Documentation

- **`docs/`** - Architecture guides and cost optimization
- **`k8s/base/grafana/README.md`** - Grafana Operator setup
- **`scripts/README.md`** - Utility scripts documentation
- **`terraform/modules/README.md`** - Infrastructure modules guide

## 💰 Cost Estimates

**Development**: ~$10-35/month
**Production**: ~$150-700/month

Costs depend on data volume and retention policies. Includes lifecycle management for cost optimization.

---

**Enterprise-grade observability stack with comprehensive monitoring, SLO tracking, and professional tooling. Ready for production deployment!**
