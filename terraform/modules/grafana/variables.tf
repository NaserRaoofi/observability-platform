# Grafana Module Variables

variable "create_workspace" {
  description = "Whether to create a managed Grafana workspace"
  type        = bool
  default     = false
}

variable "workspace_name" {
  description = "Name of the Grafana workspace"
  type        = string
  default     = "observability-grafana"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.workspace_name))
    error_message = "Workspace name can only contain alphanumeric characters, hyphens, and underscores."
  }
}

variable "workspace_description" {
  description = "Description of the Grafana workspace"
  type        = string
  default     = "Observability platform Grafana workspace"
}

variable "workspace_role_arn" {
  description = "IAM role ARN for the Grafana workspace (required if create_workspace is true)"
  type        = string
  default     = null
}

variable "prometheus_endpoint" {
  description = "Prometheus endpoint URL for data source configuration"
  type        = string
  default     = ""

  validation {
    condition = var.prometheus_endpoint == "" || can(regex("^https?://", var.prometheus_endpoint))
    error_message = "Prometheus endpoint must be a valid HTTP/HTTPS URL."
  }
}

variable "alertmanager_endpoint" {
  description = "AlertManager endpoint URL for data source configuration"
  type        = string
  default     = ""

  validation {
    condition = var.alertmanager_endpoint == "" || can(regex("^https?://", var.alertmanager_endpoint))
    error_message = "AlertManager endpoint must be a valid HTTP/HTTPS URL."
  }
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

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.grafana_folder_uid))
    error_message = "Folder UID can only contain alphanumeric characters, hyphens, and underscores."
  }
}

variable "tags" {
  description = "Tags to apply to Grafana resources"
  type        = map(string)
  default     = {}
}
