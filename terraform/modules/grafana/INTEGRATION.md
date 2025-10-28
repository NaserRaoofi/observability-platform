# Grafana Module Integration Guide

## Quick Setup

To integrate the Grafana module with your observability stack:

### 1. Add Grafana Provider

Add to your `terraform/envs/dev/main.tf` (or equivalent environment file):

```hcl
terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.0"
    }
  }
}

# Configure Grafana provider
provider "grafana" {
  # For existing Grafana instance
  url  = "http://grafana.monitoring.svc.cluster.local:3000"
  auth = "admin:admin"  # Use proper authentication in production

  # Or for AWS managed Grafana:
  # url = "https://g-xxxxxxxxxx.grafana-workspace.us-west-2.amazonaws.com"
  # cloud_api_key = "your-api-key"
}
```

### 2. Module Already Added

The Grafana module is already configured in:

- `terraform/envs/dev/main.tf` - Module definition
- `terraform/envs/dev/variables.tf` - Required variables
- `terraform/envs/dev/outputs.tf` - Module outputs
- `terraform/envs/dev/terraform.tfvars.example` - Example configuration

### 3. Configure Variables

Update your `terraform/envs/dev/terraform.tfvars`:

```hcl
# Grafana configuration
enable_grafana_dashboards = true
grafana_org_id           = "1"
prometheus_endpoint      = "http://prometheus.monitoring.svc.cluster.local:9090"
alertmanager_endpoint    = "http://alertmanager.monitoring.svc.cluster.local:9093"
```

### 4. Deploy

```bash
cd terraform/envs/dev
terraform init
terraform plan
terraform apply
```

### 5. Access Dashboards

After deployment, access your dashboards at:

- AlertManager Overview: `http://grafana-url/d/{uid}/alertmanager-overview`
- SLO Monitoring: `http://grafana-url/d/{uid}/slo-monitoring`

Dashboard UIDs are available in Terraform outputs:

```bash
terraform output grafana_dashboard_uids
```

## Data Sources Required

Ensure these data sources exist in Grafana:

- **Prometheus** (name: "Prometheus")
- **AlertManager** (name: "AlertManager")

The dashboards will automatically reference these by name.

## Troubleshooting

### Common Issues

1. **Provider authentication error**: Ensure Grafana is accessible and credentials are correct
2. **Data source not found**: Create Prometheus and AlertManager data sources in Grafana
3. **Permission denied**: Ensure the Grafana user/API key has dashboard creation permissions

### Validation Commands

```bash
# Check Terraform configuration
terraform validate

# See planned changes
terraform plan

# View current outputs
terraform output

# Check Grafana connectivity (if using port-forward)
kubectl port-forward -n monitoring service/grafana 3000:3000
```
