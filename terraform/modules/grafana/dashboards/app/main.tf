# Application Dashboards Module
# Manages application-specific monitoring dashboards

# Application folder for dashboards
resource "grafana_folder" "applications" {
  title = "Application Monitoring"
  uid   = "${var.grafana_folder_uid}-app"
}

# Data sources
data "grafana_data_source" "prometheus" {
  name = "Prometheus"
}

data "grafana_data_source" "alertmanager" {
  name = "AlertManager"
}

# TODO: Add application-specific dashboards here
# Examples:
# - API response times and error rates
# - Database performance metrics
# - Message queue monitoring
# - User journey tracking

# Module outputs
output "folder_uid" {
  description = "UID of the applications folder"
  value       = grafana_folder.applications.uid
}

# Placeholder for future dashboard outputs
output "dashboard_uids" {
  description = "UIDs of application dashboards"
  value       = {}
}
