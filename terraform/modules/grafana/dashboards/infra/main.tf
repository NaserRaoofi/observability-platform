# Infrastructure Dashboards Module
# Manages infrastructure monitoring dashboards

# Infrastructure folder for dashboards
resource "grafana_folder" "infrastructure" {
  title = "Infrastructure Monitoring"
  uid   = "${var.grafana_folder_uid}-infra"
}

# Data sources
data "grafana_data_source" "prometheus" {
  name = "Prometheus"
}

data "grafana_data_source" "alertmanager" {
  name = "AlertManager"
}

# Module outputs
output "alertmanager_dashboard_uid" {
  description = "UID of the AlertManager overview dashboard"
  value       = grafana_dashboard.alertmanager_overview.uid
}

output "folder_uid" {
  description = "UID of the infrastructure folder"
  value       = grafana_folder.infrastructure.uid
}
