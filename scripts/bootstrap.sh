#!/bin/bash

set -e

ENVIRONMENT=${1:-dev}
AWS_REGION=${AWS_REGION:-us-west-2}
PROJECT_NAME="observability-enterprise"

echo "🚀 Bootstrapping $PROJECT_NAME for environment: $ENVIRONMENT"

# Create S3 bucket for Terraform state
BUCKET_NAME="$PROJECT_NAME-terraform-state-$ENVIRONMENT-$(date +%s)"
echo "📦 Creating S3 bucket: $BUCKET_NAME"

aws s3 mb "s3://$BUCKET_NAME" --region "$AWS_REGION" || echo "Bucket might already exist"

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
TABLE_NAME="$PROJECT_NAME-terraform-locks-$ENVIRONMENT"
echo "🔒 Creating DynamoDB table: $TABLE_NAME"

aws dynamodb create-table \
    --table-name "$TABLE_NAME" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region "$AWS_REGION" || echo "Table might already exist"

# Create S3 buckets for observability data
echo "📊 Creating observability data buckets..."

LOKI_BUCKET="$PROJECT_NAME-loki-$ENVIRONMENT-$(date +%s)"
MIMIR_BUCKET="$PROJECT_NAME-mimir-$ENVIRONMENT-$(date +%s)"
TEMPO_BUCKET="$PROJECT_NAME-tempo-$ENVIRONMENT-$(date +%s)"

aws s3 mb "s3://$LOKI_BUCKET" --region "$AWS_REGION" || echo "Bucket might already exist"
aws s3 mb "s3://$MIMIR_BUCKET" --region "$AWS_REGION" || echo "Bucket might already exist"
aws s3 mb "s3://$TEMPO_BUCKET" --region "$AWS_REGION" || echo "Bucket might already exist"

# Create KMS key for encryption
echo "🔐 Creating KMS key for encryption..."
KMS_KEY=$(aws kms create-key \
    --description "Key for $PROJECT_NAME $ENVIRONMENT observability data" \
    --region "$AWS_REGION" \
    --query 'KeyMetadata.KeyId' \
    --output text) || echo "Key creation failed or already exists"

# Generate backend configuration
echo "⚙️  Generating Terraform backend configuration..."
cat > "terraform/envs/$ENVIRONMENT/backend.tf" << EOF
terraform {
  backend "s3" {
    bucket         = "$BUCKET_NAME"
    key            = "terraform.tfstate"
    region         = "$AWS_REGION"
    dynamodb_table = "$TABLE_NAME"
    encrypt        = true
  }
}
EOF

# Generate terraform.tfvars
echo "📝 Generating terraform.tfvars..."
cat > "terraform/envs/$ENVIRONMENT/terraform.tfvars" << EOF
# Environment configuration
environment = "$ENVIRONMENT"
aws_region  = "$AWS_REGION"
project_name = "$PROJECT_NAME"

# Observability data buckets
loki_bucket_name  = "$LOKI_BUCKET"
mimir_bucket_name = "$MIMIR_BUCKET"
tempo_bucket_name = "$TEMPO_BUCKET"

# KMS key for encryption
kms_key_id = "$KMS_KEY"

# EKS configuration
eks_cluster_version = "1.28"
node_instance_types = ["m5.large"]
node_desired_size   = 2
node_max_size       = 5
node_min_size       = 1

# Tags
tags = {
  Environment = "$ENVIRONMENT"
  Project     = "$PROJECT_NAME"
  ManagedBy   = "terraform"
}
EOF

echo "✅ Bootstrap complete!"
echo ""
echo "📋 Next steps:"
echo "1. Review the generated files in terraform/envs/$ENVIRONMENT/"
echo "2. Run 'make plan ENVIRONMENT=$ENVIRONMENT' to review the infrastructure plan"
echo "3. Run 'make apply ENVIRONMENT=$ENVIRONMENT' to create the infrastructure"
echo "4. Run 'make deploy-k8s ENVIRONMENT=$ENVIRONMENT' to deploy the observability stack"
echo ""
echo "🔗 Important resources created:"
echo "   - S3 bucket: $BUCKET_NAME"
echo "   - DynamoDB table: $TABLE_NAME"
echo "   - Loki bucket: $LOKI_BUCKET"
echo "   - Mimir bucket: $MIMIR_BUCKET"
echo "   - Tempo bucket: $TEMPO_BUCKET"
echo "   - KMS key: $KMS_KEY"
