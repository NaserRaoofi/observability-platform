# IAM Roles and Policies for Observability Stack
# This module creates IAM roles and policies for Mimir, Loki, and Grafana services

# Local values for consistent naming and resource references
locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = var.project_name
      Component   = "observability-iam"
      ManagedBy   = "terraform"
    }
  )

  # DynamoDB table ARNs from our DynamoDB module
  mimir_table_arn = var.mimir_table_arn
  loki_table_arn  = var.loki_table_arn

  # S3 bucket ARNs for object storage
  mimir_bucket_arn = var.mimir_s3_bucket_arn
  loki_bucket_arn  = var.loki_s3_bucket_arn
  tempo_bucket_arn = var.tempo_s3_bucket_arn
}

# ===============================================================================
# MIMIR IAM ROLE AND POLICIES
# ===============================================================================

# IAM Role for Mimir (Metrics storage and querying)
module "mimir_role" {
  source = "../../../terraform-aws-iam/modules/iam-role-for-service-accounts"

  name = "${var.project_name}-mimir-${var.environment}"

  oidc_providers = {
    main = {
      provider_arn               = var.eks_oidc_provider_arn
      namespace_service_accounts = ["${var.monitoring_namespace}:mimir"]
    }
  }

  # Attach custom policies for Mimir
  policies = {
    MimirDynamoDBAccess = module.mimir_dynamodb_policy.arn
    MimirS3Access       = module.mimir_s3_policy.arn
    CloudWatchMetrics   = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }

  tags = local.common_tags
}

# Custom DynamoDB policy for Mimir
module "mimir_dynamodb_policy" {
  source = "../../../terraform-aws-iam/modules/iam-policy"

  name_prefix = "mimir-dynamodb-${var.environment}-"
  description = "DynamoDB access policy for Mimir metrics storage"

  policy = data.aws_iam_policy_document.mimir_dynamodb.json

  tags = local.common_tags
}

# Custom S3 policy for Mimir
module "mimir_s3_policy" {
  source = "../../../terraform-aws-iam/modules/iam-policy"

  name_prefix = "mimir-s3-${var.environment}-"
  description = "S3 access policy for Mimir object storage"

  policy = data.aws_iam_policy_document.mimir_s3.json

  tags = local.common_tags
}

# ===============================================================================
# LOKI IAM ROLE AND POLICIES
# ===============================================================================

# IAM Role for Loki (Logs storage and querying)
module "loki_role" {
  source = "../../../terraform-aws-iam/modules/iam-role-for-service-accounts"

  count = var.create_loki_resources ? 1 : 0

  name = "${var.project_name}-loki-${var.environment}"

  oidc_providers = {
    main = {
      provider_arn               = var.eks_oidc_provider_arn
      namespace_service_accounts = ["${var.monitoring_namespace}:loki"]
    }
  }

  # Attach custom policies for Loki
  policies = {
    LokiDynamoDBAccess = module.loki_dynamodb_policy[0].arn
    LokiS3Access       = module.loki_s3_policy[0].arn
    CloudWatchLogs     = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  }

  tags = local.common_tags
}

# Custom DynamoDB policy for Loki
module "loki_dynamodb_policy" {
  source = "../../../terraform-aws-iam/modules/iam-policy"

  count = var.create_loki_resources ? 1 : 0

  name_prefix = "loki-dynamodb-${var.environment}-"
  description = "DynamoDB access policy for Loki logs indexing"

  policy = data.aws_iam_policy_document.loki_dynamodb.json

  tags = local.common_tags
}

# Custom S3 policy for Loki
module "loki_s3_policy" {
  source = "../../../terraform-aws-iam/modules/iam-policy"

  count = var.create_loki_resources ? 1 : 0

  name_prefix = "loki-s3-${var.environment}-"
  description = "S3 access policy for Loki object storage"

  policy = data.aws_iam_policy_document.loki_s3.json

  tags = local.common_tags
}

# ===============================================================================
# GRAFANA IAM ROLE AND POLICIES
# ===============================================================================

# IAM Role for Grafana (Dashboard and visualization)
module "grafana_role" {
  source = "../../../terraform-aws-iam/modules/iam-role-for-service-accounts"

  count = var.create_grafana_resources ? 1 : 0

  name = "${var.project_name}-grafana-${var.environment}"

  oidc_providers = {
    main = {
      provider_arn               = var.eks_oidc_provider_arn
      namespace_service_accounts = ["${var.monitoring_namespace}:grafana"]
    }
  }

  # Grafana needs read-only access to various AWS services
  policies = {
    CloudWatchReadOnly    = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
    PrometheusReadOnly    = module.grafana_prometheus_policy[0].arn
    ObservabilityReadOnly = module.grafana_observability_policy[0].arn
  }

  tags = local.common_tags
}

# Read-only policy for Grafana to access Prometheus/Mimir
module "grafana_prometheus_policy" {
  source = "../../../terraform-aws-iam/modules/iam-policy"

  count = var.create_grafana_resources ? 1 : 0

  name_prefix = "grafana-prometheus-${var.environment}-"
  description = "Read-only access policy for Grafana to query Prometheus/Mimir"

  policy = data.aws_iam_policy_document.grafana_prometheus.json

  tags = local.common_tags
}

# Read-only policy for Grafana to access observability resources
module "grafana_observability_policy" {
  source = "../../../terraform-aws-iam/modules/iam-policy"

  count = var.create_grafana_resources ? 1 : 0

  name_prefix = "grafana-observability-${var.environment}-"
  description = "Read-only access policy for Grafana to observability resources"

  policy = data.aws_iam_policy_document.grafana_observability.json

  tags = local.common_tags
}

# ===============================================================================
# TEMPO IAM ROLE AND POLICIES
# ===============================================================================

# IAM Role for Tempo (Distributed tracing storage)
module "tempo_role" {
  source = "../../../terraform-aws-iam/modules/iam-role-for-service-accounts"

  count = var.create_tempo_resources ? 1 : 0

  name = "${var.project_name}-tempo-${var.environment}"

  oidc_providers = {
    main = {
      provider_arn               = var.eks_oidc_provider_arn
      namespace_service_accounts = ["${var.monitoring_namespace}:tempo"]
    }
  }

  # Attach custom policies for Tempo
  policies = merge(
    {
      TempoS3Access = module.tempo_s3_policy[0].arn
    },
    var.tempo_additional_policies
  )

  tags = local.common_tags
}

# Custom S3 policy for Tempo
module "tempo_s3_policy" {
  source = "../../../terraform-aws-iam/modules/iam-policy"

  count = var.create_tempo_resources ? 1 : 0

  name_prefix = "tempo-s3-${var.environment}-"
  description = "S3 access policy for Tempo traces storage"

  policy = data.aws_iam_policy_document.tempo_s3[0].json

  tags = local.common_tags
}
