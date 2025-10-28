# Grafana Dashboards for Observability Platform
# Organized dashboard modules by category for clean structure

# Variables for dashboard configuration
variable "grafana_org_id" {
  description = "Grafana organization ID"
  type        = number
  default     = 1
}

variable "grafana_folder_uid" {
  description = "Base UID for Grafana folders"
  type        = string
  default     = "observability"
}

# Infrastructure Dashboards Module
module "infrastructure_dashboards" {
  source = "./infra"

  grafana_folder_uid = var.grafana_folder_uid
}

# SLO Dashboards Module
module "slo_dashboards" {
  source = "./slo"

  grafana_folder_uid = var.grafana_folder_uid
}

# Application Dashboards Module (placeholder)
module "application_dashboards" {
  source = "./app"

  grafana_folder_uid = var.grafana_folder_uid
}

# SRE Dashboards Module (placeholder)
module "sre_dashboards" {
  source = "./sre"

  grafana_folder_uid = var.grafana_folder_uid
}

# Consolidated outputs for all dashboard categories
output "alertmanager_dashboard_uid" {
  description = "UID of the AlertManager overview dashboard"
  value       = module.infrastructure_dashboards.alertmanager_dashboard_uid
}

output "slo_dashboard_uid" {
  description = "UID of the SLO monitoring dashboard"
  value       = module.slo_dashboards.slo_dashboard_uid
}

output "folder_uids" {
  description = "UIDs of all dashboard folders"
  value = {
    infrastructure = module.infrastructure_dashboards.folder_uid
    slo           = module.slo_dashboards.folder_uid
    applications  = module.application_dashboards.folder_uid
    sre          = module.sre_dashboards.folder_uid
  }
}

# Legacy single folder output for backward compatibility
output "folder_uid" {
  description = "UID of the infrastructure folder (for backward compatibility)"
  value       = module.infrastructure_dashboards.folder_uid
}
