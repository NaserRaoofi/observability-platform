# ===============================================================================
# IAM ROLE OUTPUTS FOR KUBERNETES SERVICE ACCOUNTS
# ===============================================================================

# ===============================================================================
# MIMIR ROLE OUTPUTS
# ===============================================================================

output "mimir_role_arn" {
  description = "ARN of the Mimir IAM role for IRSA"
  value       = module.mimir_role.iam_role_arn
}

output "mimir_role_name" {
  description = "Name of the Mimir IAM role"
  value       = module.mimir_role.iam_role_name
}

output "mimir_service_account_annotation" {
  description = "Annotation to add to Mimir Kubernetes service account"
  value = {
    "eks.amazonaws.com/role-arn" = module.mimir_role.iam_role_arn
  }
}

# ===============================================================================
# LOKI ROLE OUTPUTS (Conditional)
# ===============================================================================

output "loki_role_arn" {
  description = "ARN of the Loki IAM role for IRSA (if created)"
  value       = var.create_loki_resources ? module.loki_role[0].iam_role_arn : null
}

output "loki_role_name" {
  description = "Name of the Loki IAM role (if created)"
  value       = var.create_loki_resources ? module.loki_role[0].iam_role_name : null
}

output "loki_service_account_annotation" {
  description = "Annotation to add to Loki Kubernetes service account (if created)"
  value = var.create_loki_resources ? {
    "eks.amazonaws.com/role-arn" = module.loki_role[0].iam_role_arn
  } : null
}

# ===============================================================================
# GRAFANA ROLE OUTPUTS (Conditional)
# ===============================================================================

output "grafana_role_arn" {
  description = "ARN of the Grafana IAM role for IRSA (if created)"
  value       = var.create_grafana_resources ? module.grafana_role[0].iam_role_arn : null
}

output "grafana_role_name" {
  description = "Name of the Grafana IAM role (if created)"
  value       = var.create_grafana_resources ? module.grafana_role[0].iam_role_name : null
}

output "grafana_service_account_annotation" {
  description = "Annotation to add to Grafana Kubernetes service account (if created)"
  value = var.create_grafana_resources ? {
    "eks.amazonaws.com/role-arn" = module.grafana_role[0].iam_role_arn
  } : null
}

# ===============================================================================
# TEMPO ROLE OUTPUTS (Conditional)
# ===============================================================================

output "tempo_role_arn" {
  description = "ARN of the Tempo IAM role for IRSA (if created)"
  value       = var.create_tempo_resources ? module.tempo_role[0].iam_role_arn : null
}

output "tempo_role_name" {
  description = "Name of the Tempo IAM role (if created)"
  value       = var.create_tempo_resources ? module.tempo_role[0].iam_role_name : null
}

output "tempo_service_account_annotation" {
  description = "Annotation to add to Tempo Kubernetes service account (if created)"
  value = var.create_tempo_resources ? {
    "eks.amazonaws.com/role-arn" = module.tempo_role[0].iam_role_arn
  } : null
}

# ===============================================================================
# POLICY OUTPUTS
# ===============================================================================

output "mimir_dynamodb_policy_arn" {
  description = "ARN of the Mimir DynamoDB access policy"
  value       = module.mimir_dynamodb_policy.arn
}

output "mimir_s3_policy_arn" {
  description = "ARN of the Mimir S3 access policy"
  value       = module.mimir_s3_policy.arn
}

output "loki_dynamodb_policy_arn" {
  description = "ARN of the Loki DynamoDB access policy (if created)"
  value       = var.create_loki_resources ? module.loki_dynamodb_policy[0].arn : null
}

output "loki_s3_policy_arn" {
  description = "ARN of the Loki S3 access policy (if created)"
  value       = var.create_loki_resources ? module.loki_s3_policy[0].arn : null
}

output "tempo_s3_policy_arn" {
  description = "ARN of the Tempo S3 access policy (if created)"
  value       = var.create_tempo_resources ? module.tempo_s3_policy[0].arn : null
}

# ===============================================================================
# KUBERNETES INTEGRATION OUTPUTS
# ===============================================================================

output "service_account_annotations" {
  description = "Map of service account annotations for easy Kubernetes integration"
  value = {
    mimir = {
      "eks.amazonaws.com/role-arn" = module.mimir_role.iam_role_arn
    }
    loki = var.create_loki_resources ? {
      "eks.amazonaws.com/role-arn" = module.loki_role[0].iam_role_arn
    } : {}
    grafana = var.create_grafana_resources ? {
      "eks.amazonaws.com/role-arn" = module.grafana_role[0].iam_role_arn
    } : {}
    tempo = var.create_tempo_resources ? {
      "eks.amazonaws.com/role-arn" = module.tempo_role[0].iam_role_arn
    } : {}
  }
}

# ===============================================================================
# ROLE SUMMARY FOR DOCUMENTATION
# ===============================================================================

output "roles_summary" {
  description = "Summary of all created IAM roles for documentation"
  value = {
    mimir = {
      role_arn                   = module.mimir_role.iam_role_arn
      role_name                  = module.mimir_role.iam_role_name
      kubernetes_namespace       = var.monitoring_namespace
      kubernetes_service_account = "mimir"
      permissions                = ["DynamoDB:ReadWrite", "S3:ReadWrite", "CloudWatch:Metrics"]
    }
    loki = var.create_loki_resources ? {
      role_arn                   = module.loki_role[0].iam_role_arn
      role_name                  = module.loki_role[0].iam_role_name
      kubernetes_namespace       = var.monitoring_namespace
      kubernetes_service_account = "loki"
      permissions                = ["DynamoDB:ReadWrite", "S3:ReadWrite", "CloudWatch:Logs"]
    } : null
    grafana = var.create_grafana_resources ? {
      role_arn                   = module.grafana_role[0].iam_role_arn
      role_name                  = module.grafana_role[0].iam_role_name
      kubernetes_namespace       = var.monitoring_namespace
      kubernetes_service_account = "grafana"
      permissions                = ["CloudWatch:ReadOnly", "Prometheus:ReadOnly"]
    } : null
    tempo = var.create_tempo_resources ? {
      role_arn                   = module.tempo_role[0].iam_role_arn
      role_name                  = module.tempo_role[0].iam_role_name
      kubernetes_namespace       = var.monitoring_namespace
      kubernetes_service_account = "tempo"
      permissions                = ["S3:ReadWrite"]
    } : null
  }
}
