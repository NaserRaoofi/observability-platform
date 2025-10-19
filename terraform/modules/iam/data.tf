# ===============================================================================
# IAM POLICY DOCUMENTS FOR OBSERVABILITY SERVICES
# ===============================================================================

# ===============================================================================
# MIMIR DYNAMODB POLICY
# ===============================================================================

data "aws_iam_policy_document" "mimir_dynamodb" {
  # Full access to Mimir DynamoDB table for metrics indexing
  statement {
    sid    = "MimirDynamoDBTableAccess"
    effect = "Allow"

    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:ConditionCheckItem"
    ]

    resources = [
      local.mimir_table_arn,
      "${local.mimir_table_arn}/index/*"
    ]
  }

  # DynamoDB streams access for real-time processing
  statement {
    sid    = "MimirDynamoDBStreamsAccess"
    effect = "Allow"

    actions = [
      "dynamodb:DescribeStream",
      "dynamodb:GetRecords",
      "dynamodb:GetShardIterator",
      "dynamodb:ListStreams"
    ]

    resources = [
      "${local.mimir_table_arn}/stream/*"
    ]
  }

  # General DynamoDB permissions for table operations
  statement {
    sid    = "MimirDynamoDBGeneralAccess"
    effect = "Allow"

    actions = [
      "dynamodb:DescribeReservedCapacity",
      "dynamodb:DescribeReservedCapacityOfferings",
      "dynamodb:ListTables",
      "dynamodb:DescribeTimeToLive",
      "dynamodb:DescribeLimits"
    ]

    resources = ["*"]
  }
}

# ===============================================================================
# MIMIR S3 POLICY
# ===============================================================================

data "aws_iam_policy_document" "mimir_s3" {
  # Object-level access for metrics storage
  statement {
    sid    = "MimirS3ObjectAccess"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:GetObjectVersion",
      "s3:RestoreObject"
    ]

    resources = [
      "${local.mimir_bucket_arn}/*"
    ]
  }

  # Bucket-level access for listing and management
  statement {
    sid    = "MimirS3BucketAccess"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetBucketVersioning",
      "s3:ListBucketVersions",
      "s3:ListBucketMultipartUploads"
    ]

    resources = [
      local.mimir_bucket_arn
    ]
  }

  # Multipart upload support for large objects
  statement {
    sid    = "MimirS3MultipartAccess"
    effect = "Allow"

    actions = [
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts"
    ]

    resources = [
      "${local.mimir_bucket_arn}/*"
    ]
  }
}

# ===============================================================================
# LOKI DYNAMODB POLICY
# ===============================================================================

data "aws_iam_policy_document" "loki_dynamodb" {
  # Full access to Loki DynamoDB table for log indexing
  statement {
    sid    = "LokiDynamoDBTableAccess"
    effect = "Allow"

    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem"
    ]

    resources = [
      local.loki_table_arn != null ? local.loki_table_arn : "",
      local.loki_table_arn != null ? "${local.loki_table_arn}/index/*" : ""
    ]
  }

  # General DynamoDB permissions for Loki
  statement {
    sid    = "LokiDynamoDBGeneralAccess"
    effect = "Allow"

    actions = [
      "dynamodb:ListTables",
      "dynamodb:DescribeTimeToLive",
      "dynamodb:DescribeLimits"
    ]

    resources = ["*"]
  }
}

# ===============================================================================
# LOKI S3 POLICY
# ===============================================================================

data "aws_iam_policy_document" "loki_s3" {
  # Object-level access for log storage
  statement {
    sid    = "LokiS3ObjectAccess"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:GetObjectVersion"
    ]

    resources = [
      local.loki_bucket_arn != null ? "${local.loki_bucket_arn}/*" : ""
    ]
  }

  # Bucket-level access for Loki
  statement {
    sid    = "LokiS3BucketAccess"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:ListBucketMultipartUploads"
    ]

    resources = [
      local.loki_bucket_arn != null ? local.loki_bucket_arn : ""
    ]
  }
}

# ===============================================================================
# GRAFANA PROMETHEUS/MIMIR POLICY
# ===============================================================================

data "aws_iam_policy_document" "grafana_prometheus" {
  # Read-only access to metrics data sources
  statement {
    sid    = "GrafanaPrometheusReadAccess"
    effect = "Allow"

    actions = [
      "aps:ListWorkspaces",
      "aps:DescribeWorkspace",
      "aps:QueryMetrics",
      "aps:GetLabels",
      "aps:GetSeries",
      "aps:GetMetricMetadata"
    ]

    resources = ["*"]
  }

  # CloudWatch metrics access for Grafana
  statement {
    sid    = "GrafanaCloudWatchMetricsAccess"
    effect = "Allow"

    actions = [
      "cloudwatch:DescribeAlarmsForMetric",
      "cloudwatch:DescribeAlarmHistory",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:ListMetrics",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:GetMetricData"
    ]

    resources = ["*"]
  }
}

# ===============================================================================
# GRAFANA OBSERVABILITY RESOURCES POLICY
# ===============================================================================

data "aws_iam_policy_document" "grafana_observability" {
  # Read-only access to observability resources
  statement {
    sid    = "GrafanaObservabilityReadAccess"
    effect = "Allow"

    actions = [
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:FilterLogEvents",
      "logs:GetLogEvents",
      "logs:StartQuery",
      "logs:StopQuery",
      "logs:GetQueryResults"
    ]

    resources = ["*"]
  }

  # EC2 and EKS resource discovery
  statement {
    sid    = "GrafanaResourceDiscovery"
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ec2:DescribeAvailabilityZones",
      "eks:DescribeCluster",
      "eks:ListClusters"
    ]

    resources = ["*"]
  }

  # Tag-based resource filtering
  statement {
    sid    = "GrafanaTagAccess"
    effect = "Allow"

    actions = [
      "tag:GetResources",
      "tag:GetTagKeys",
      "tag:GetTagValues"
    ]

    resources = ["*"]
  }
}

# ===============================================================================
# TEMPO S3 POLICY
# ===============================================================================

data "aws_iam_policy_document" "tempo_s3" {
  count = var.create_tempo_resources ? 1 : 0

  # Object-level access for trace storage
  statement {
    sid    = "TempoS3ObjectAccess"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:GetObjectVersion"
    ]

    resources = [
      local.tempo_bucket_arn != null ? "${local.tempo_bucket_arn}/*" : ""
    ]
  }

  # Bucket-level access for Tempo
  statement {
    sid    = "TempoS3BucketAccess"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:ListBucketMultipartUploads",
      "s3:AbortMultipartUpload"
    ]

    resources = [
      local.tempo_bucket_arn != null ? local.tempo_bucket_arn : ""
    ]
  }

  # S3 multipart upload operations for large traces
  statement {
    sid    = "TempoS3MultipartAccess"
    effect = "Allow"

    actions = [
      "s3:ListMultipartUploadParts",
      "s3:CompleteMultipartUpload",
      "s3:AbortMultipartUpload"
    ]

    resources = [
      local.tempo_bucket_arn != null ? "${local.tempo_bucket_arn}/*" : ""
    ]
  }
}
