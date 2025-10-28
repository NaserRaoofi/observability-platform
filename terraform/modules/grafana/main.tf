# Main Grafana Module Configuration
# Manages Grafana workspace, data sources, and dashboards

terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.0"
    }
  }
}

# Variables
variable "create_workspace" {
  description = "Whether to create a managed Grafana workspace"
  type        = bool
  default     = false
}

variable "workspace_name" {
  description = "Name of the Grafana workspace"
  type        = string
  default     = "observability-grafana"
}

variable "workspace_description" {
  description = "Description of the Grafana workspace"
  type        = string
  default     = "Observability platform Grafana workspace"
}

variable "workspace_role_arn" {
  description = "IAM role ARN for the Grafana workspace"
  type        = string
  default     = null
}

variable "prometheus_endpoint" {
  description = "Prometheus endpoint URL"
  type        = string
  default     = ""
}

variable "alertmanager_endpoint" {
  description = "AlertManager endpoint URL"
  type        = string
  default     = ""
}

variable "enable_dashboards" {
  description = "Whether to create Grafana dashboards"
  type        = bool
  default     = true
}

variable "grafana_org_id" {
  description = "Grafana organization ID for dashboards"
  type        = string
  default     = "1"
}

variable "grafana_folder_uid" {
  description = "Grafana folder UID for organizing dashboards"
  type        = string
  default     = "observability"
}

# Data sources for existing Grafana instance (if not creating workspace)
data "grafana_data_source" "existing_prometheus" {
  count = var.prometheus_endpoint != "" && !var.create_workspace ? 1 : 0
  name  = "Prometheus"
}

data "grafana_data_source" "existing_alertmanager" {
  count = var.alertmanager_endpoint != "" && !var.create_workspace ? 1 : 0
  name  = "AlertManager"
}

# Dashboard module
module "dashboards" {
  count  = var.enable_dashboards ? 1 : 0
  source = "./dashboards"

  grafana_org_id     = var.grafana_org_id
  grafana_folder_uid = var.grafana_folder_uid
}

# Outputs
output "workspace_endpoint" {
  description = "Grafana workspace endpoint (if created)"
  value       = null # Would be set if creating AWS managed Grafana
}

output "dashboard_uids" {
  description = "UIDs of created dashboards"
  value = var.enable_dashboards ? {
    alertmanager_overview = module.dashboards[0].alertmanager_dashboard_uid
    slo_monitoring       = module.dashboards[0].slo_dashboard_uid
  } : {}
}

output "folder_uids" {
  description = "UIDs of dashboard folders organized by category"
  value = var.enable_dashboards ? module.dashboards[0].folder_uids : {}
}

output "data_source_names" {
  description = "Names of configured data sources"
  value = {
    prometheus    = var.prometheus_endpoint != "" ? "Prometheus" : null
    alertmanager = var.alertmanager_endpoint != "" ? "AlertManager" : null
  }
}
