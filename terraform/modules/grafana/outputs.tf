# Grafana Module Outputs

output "workspace_id" {
  description = "ID of the Grafana workspace (if created)"
  value       = null # Would be populated if creating AWS managed Grafana
}

output "workspace_endpoint" {
  description = "Grafana workspace endpoint URL (if created)"
  value       = null # Would be populated if creating AWS managed Grafana
}

output "workspace_status" {
  description = "Status of the Grafana workspace (if created)"
  value       = null # Would be populated if creating AWS managed Grafana
}

# Dashboard outputs
output "dashboard_uids" {
  description = "UIDs of created dashboards"
  value = var.enable_dashboards ? {
    alertmanager_overview = module.dashboards[0].alertmanager_dashboard_uid
    slo_monitoring       = module.dashboards[0].slo_dashboard_uid
  } : {}
}

output "dashboard_urls" {
  description = "URLs to access the dashboards (requires workspace endpoint)"
  value = var.enable_dashboards ? {
    alertmanager_overview = module.dashboards[0].alertmanager_dashboard_uid != null ? "d/${module.dashboards[0].alertmanager_dashboard_uid}/alertmanager-overview" : null
    slo_monitoring       = module.dashboards[0].slo_dashboard_uid != null ? "d/${module.dashboards[0].slo_dashboard_uid}/slo-monitoring" : null
  } : {}
}

# Folder outputs
output "folder_uids" {
  description = "UIDs of dashboard folders organized by category"
  value = var.enable_dashboards ? module.dashboards[0].folder_uids : {}
}

output "folder_uid" {
  description = "UID of the infrastructure folder (backward compatibility)"
  value       = var.enable_dashboards ? module.dashboards[0].folder_uid : null
}

# Data source information
output "data_source_config" {
  description = "Configuration information for data sources"
  value = {
    prometheus_endpoint    = var.prometheus_endpoint
    alertmanager_endpoint = var.alertmanager_endpoint
    prometheus_configured = var.prometheus_endpoint != ""
    alertmanager_configured = var.alertmanager_endpoint != ""
  }
}

# Module configuration summary
output "module_config" {
  description = "Summary of module configuration"
  value = {
    workspace_created     = var.create_workspace
    dashboards_enabled   = var.enable_dashboards
    dashboards_count     = var.enable_dashboards ? 2 : 0
    grafana_org_id       = var.grafana_org_id
    grafana_folder_uid   = var.grafana_folder_uid
  }
}
