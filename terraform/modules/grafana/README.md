# Grafana Module

This module manages Grafana dashboards and optionally creates AWS managed Grafana workspaces for the observability platform.

## Features

- **Infrastructure as Code Dashboards**: Creates Grafana dashboards using Terraform instead of JSON files
- **Organized Dashboard Management**: Creates a dedicated folder for observability dashboards
- **Pre-built Dashboards**: Includes comprehensive AlertManager and SLO monitoring dashboards
- **Flexible Data Source Configuration**: Supports both existing and new Grafana instances
- **AWS Managed Grafana Support**: Optionally creates managed Grafana workspaces

## Included Dashboards

### 1. AlertManager Overview Dashboard

- **UID**: `alertmanager-overview`
- **Panels**: 7 comprehensive monitoring panels
  - Alerts by State (gauge visualization)
  - Active Alerts Count (stat panel)
  - Notification Success Rate (stat panel)
  - Notification Rate (time series graph)
  - AlertManager Cluster Status (table)
  - Notification Errors (time series graph)
  - Current Active Alerts (detailed table)

### 2. SLO Monitoring Dashboard

- **UID**: `slo-monitoring`
- **Panels**: 8 SLO-focused panels
  - Error Budget Remaining (gauge)
  - Current SLO Performance (stat)
  - Error Budget Burn Rate (gauge)
  - Active SLO Alerts (stat)
  - SLO Performance vs Target (time series)
  - Error Budget Burn Rate Trend (time series)
  - SLO Alert Details (table with AlertManager integration)
  - SLO Performance by Service (time series with service variable)

## Usage

### Basic Dashboard Creation

```hcl
module "grafana_dashboards" {
  source = "../../modules/grafana"

  # Enable dashboard creation
  enable_dashboards = true

  # Configure Grafana organization
  grafana_org_id = "1"

  # Data source endpoints
  prometheus_endpoint   = "http://prometheus.monitoring.svc.cluster.local:9090"
  alertmanager_endpoint = "http://alertmanager.monitoring.svc.cluster.local:9093"
}
```

### Complete Configuration with AWS Managed Grafana

```hcl
module "observability_grafana" {
  source = "../../modules/grafana"

  # Dashboard configuration
  enable_dashboards    = true
  grafana_org_id      = "1"
  grafana_folder_uid  = "observability-${var.environment}"

  # Data source endpoints
  prometheus_endpoint   = "https://prometheus.example.com"
  alertmanager_endpoint = "https://alertmanager.example.com"

  # AWS managed workspace (optional)
  create_workspace      = true
  workspace_name        = "${var.project_name}-${var.environment}"
  workspace_description = "Observability platform Grafana workspace"
  workspace_role_arn    = module.iam.grafana_role_arn

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
```

## Requirements

### Terraform Providers

```hcl
terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.0"
    }
  }
}
```

### Grafana Provider Configuration

```hcl
# For existing Grafana instance
provider "grafana" {
  url  = "https://your-grafana-instance.com"
  auth = "your-api-key-or-basic-auth"
}

# For AWS managed Grafana
provider "grafana" {
  url = "https://g-xxxxxxxxxx.grafana-workspace.us-west-2.amazonaws.com"

  # Use AWS authentication
  cloud_api_key = "your-aws-managed-grafana-key"
}
```

## Variables

| Name                    | Description                                 | Type          | Default                                      | Required |
| ----------------------- | ------------------------------------------- | ------------- | -------------------------------------------- | -------- |
| `create_workspace`      | Whether to create managed Grafana workspace | `bool`        | `false`                                      | no       |
| `workspace_name`        | Name of the Grafana workspace               | `string`      | `"observability-grafana"`                    | no       |
| `workspace_description` | Description of workspace                    | `string`      | `"Observability platform Grafana workspace"` | no       |
| `workspace_role_arn`    | IAM role ARN for workspace                  | `string`      | `null`                                       | no       |
| `prometheus_endpoint`   | Prometheus endpoint URL                     | `string`      | `""`                                         | no       |
| `alertmanager_endpoint` | AlertManager endpoint URL                   | `string`      | `""`                                         | no       |
| `enable_dashboards`     | Whether to create dashboards                | `bool`        | `true`                                       | no       |
| `grafana_org_id`        | Grafana organization ID                     | `string`      | `"1"`                                        | no       |
| `grafana_folder_uid`    | Folder UID for dashboards                   | `string`      | `"observability"`                            | no       |
| `tags`                  | Tags to apply to resources                  | `map(string)` | `{}`                                         | no       |

## Outputs

| Name                 | Description                             |
| -------------------- | --------------------------------------- |
| `dashboard_uids`     | UIDs of created dashboards              |
| `dashboard_urls`     | Relative URLs for dashboard access      |
| `folder_uid`         | UID of the Grafana folder               |
| `workspace_endpoint` | Grafana workspace endpoint (if created) |
| `data_source_config` | Data source configuration summary       |
| `module_config`      | Module configuration summary            |

## Dashboard Access

After deployment, dashboards will be available at:

- **AlertManager Overview**: `https://your-grafana-url/d/{dashboard_uid}/alertmanager-overview`
- **SLO Monitoring**: `https://your-grafana-url/d/{dashboard_uid}/slo-monitoring`

The exact dashboard UIDs are available in the `dashboard_uids` output.

## Data Sources Required

Both dashboards expect the following Grafana data sources to be configured:

1. **Prometheus**: Named "Prometheus" - for metrics collection
2. **AlertManager**: Named "AlertManager" - for alert information

The module will automatically reference these data sources by name.

## Migration from JSON

If you have existing JSON dashboard files, this Terraform module provides a cleaner Infrastructure as Code approach:

**Before** (JSON files):

```
k8s/base/grafana/dashboards/
├── alertmanager-overview.json
└── slo-monitoring.json
```

**After** (Terraform):

```
terraform/modules/grafana/dashboards/
├── main.tf
├── alertmanager-overview.tf
└── slo-monitoring.tf
```

Benefits of Terraform approach:

- Version controlled infrastructure
- Environment-specific customization
- Automatic dependency management
- Integration with other Terraform resources
- Proper lifecycle management

## Examples

See `terraform/envs/dev/` for a complete example of integrating this module with the full observability stack.
