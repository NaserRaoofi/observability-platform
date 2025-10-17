# KMS Encryption Policies

This document outlines the KMS (Key Management Service) encryption policies and practices used in the observability enterprise stack.

## Key Management Strategy

### 1. Key Structure

- **One KMS key per environment** (dev, prod)
- **Separate keys for different data types** when required by compliance
- **Key rotation enabled** (annual automatic rotation)

### 2. Key Policies

#### Default Key Policy Template

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow use of the key for observability services",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::${account_id}:role/observability-loki-role",
          "arn:aws:iam::${account_id}:role/observability-mimir-role",
          "arn:aws:iam::${account_id}:role/observability-tempo-role"
        ]
      },
      "Action": ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"],
      "Resource": "*"
    },
    {
      "Sid": "Allow attachment of persistent resources",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::${account_id}:role/observability-loki-role",
          "arn:aws:iam::${account_id}:role/observability-mimir-role",
          "arn:aws:iam::${account_id}:role/observability-tempo-role"
        ]
      },
      "Action": ["kms:CreateGrant", "kms:ListGrants", "kms:RevokeGrant"],
      "Resource": "*",
      "Condition": {
        "Bool": {
          "kms:GrantIsForAWSResource": "true"
        }
      }
    }
  ]
}
```

## Encryption Scope

### 1. S3 Bucket Encryption

- **Loki Logs**: Server-side encryption with KMS
- **Mimir Metrics**: Server-side encryption with KMS
- **Tempo Traces**: Server-side encryption with KMS
- **Terraform State**: Server-side encryption with KMS

### 2. EBS Volume Encryption

- **EKS Node Groups**: Encrypted with KMS key
- **PVC Storage**: Encrypted by default storage class

### 3. In-Transit Encryption

- **Inter-service communication**: TLS 1.2+
- **Client-to-service**: TLS 1.2+
- **S3 communication**: HTTPS only

## Key Rotation

### Automatic Rotation

- **Frequency**: Annual
- **Services affected**: All observability components
- **Monitoring**: CloudWatch alarms for key usage

### Manual Rotation Process

1. Create new KMS key
2. Update Terraform configurations
3. Update service configurations
4. Verify encryption with new key
5. Schedule old key for deletion (30-day waiting period)

## Access Controls

### Principle of Least Privilege

- Each service has its own IAM role
- KMS permissions scoped to specific actions
- Cross-account access denied by default

### Monitoring and Auditing

- **CloudTrail**: All KMS API calls logged
- **CloudWatch**: Key usage metrics
- **AWS Config**: Key configuration compliance

## Compliance Considerations

### SOC 2 Type II

- Key access logging
- Segregation of duties
- Regular access reviews

### PCI DSS (if applicable)

- Key escrow procedures
- Dual control for key management
- Regular penetration testing

## Emergency Procedures

### Key Compromise Response

1. Immediately disable compromised key
2. Create new replacement key
3. Re-encrypt affected data
4. Update all service configurations
5. Conduct security review

### Data Recovery

- **Backup keys**: Stored in separate AWS account
- **Recovery procedures**: Documented and tested
- **RTO**: < 4 hours for key restoration

## Implementation Checklist

- [ ] KMS key created per environment
- [ ] Key policies applied and tested
- [ ] Service roles configured with minimal permissions
- [ ] Monitoring and alerting configured
- [ ] Backup and recovery procedures tested
- [ ] Documentation updated
- [ ] Team training completed
