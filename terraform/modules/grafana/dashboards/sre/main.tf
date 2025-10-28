# SRE Dashboards Module
# Manages Site Reliability Engineering operational dashboards

# SRE folder for dashboards
resource "grafana_folder" "sre" {
  title = "SRE Operations"
  uid   = "${var.grafana_folder_uid}-sre"
}

# Data sources
data "grafana_data_source" "prometheus" {
  name = "Prometheus"
}

data "grafana_data_source" "alertmanager" {
  name = "AlertManager"
}

# TODO: Add SRE-specific dashboards here
# Examples:
# - Incident response metrics
# - Change failure rates
# - Mean time to recovery (MTTR)
# - Deployment frequency tracking
# - Error budget burn rates across services

# Module outputs
output "folder_uid" {
  description = "UID of the SRE folder"
  value       = grafana_folder.sre.uid
}

# Placeholder for future dashboard outputs
output "dashboard_uids" {
  description = "UIDs of SRE dashboards"
  value       = {}
}
