# SLO Dashboards Module
# Manages Service Level Objective monitoring dashboards

# SLO folder for dashboards
resource "grafana_folder" "slo" {
  title = "SLO Monitoring"
  uid   = "${var.grafana_folder_uid}-slo"
}

# Data sources
data "grafana_data_source" "prometheus" {
  name = "Prometheus"
}

data "grafana_data_source" "alertmanager" {
  name = "AlertManager"
}

# Module outputs
output "slo_dashboard_uid" {
  description = "UID of the SLO monitoring dashboard"
  value       = grafana_dashboard.slo_monitoring.uid
}

output "folder_uid" {
  description = "UID of the SLO folder"
  value       = grafana_folder.slo.uid
}
