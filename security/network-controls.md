# Network Security Controls

This document outlines the network security controls implemented in the observability enterprise stack to ensure secure communication and data isolation.

## Network Architecture Overview

```
Internet Gateway
        |
   ALB (Public)
        |
    NAT Gateway
        |
   Private Subnets (EKS Nodes)
        |
   Database Subnets (RDS, DynamoDB)
```

## VPC Configuration

### Subnets

- **Public Subnets**: 2 AZs for load balancers and NAT gateways
- **Private Subnets**: 2 AZs for EKS worker nodes
- **Database Subnets**: 2 AZs for managed services

### CIDR Blocks

```
Production:
- VPC: 10.0.0.0/16
- Public Subnets: 10.0.1.0/24, 10.0.2.0/24
- Private Subnets: 10.0.10.0/24, 10.0.11.0/24
- Database Subnets: 10.0.20.0/24, 10.0.21.0/24

Development:
- VPC: 10.1.0.0/16
- Public Subnets: 10.1.1.0/24, 10.1.2.0/24
- Private Subnets: 10.1.10.0/24, 10.1.11.0/24
- Database Subnets: 10.1.20.0/24, 10.1.21.0/24
```

## Security Groups

### 1. EKS Control Plane Security Group

```yaml
Rules:
  Ingress:
    - Port: 443
      Source: EKS Node Security Group
      Description: "HTTPS from worker nodes"
    - Port: 443
      Source: Admin CIDR blocks
      Description: "HTTPS from administrators"

  Egress:
    - Port: All
      Destination: 0.0.0.0/0
      Description: "All outbound traffic"
```

### 2. EKS Node Security Group

```yaml
Rules:
  Ingress:
    - Port: All
      Source: Self
      Description: "All traffic within cluster"
    - Port: 443
      Source: EKS Control Plane
      Description: "HTTPS from control plane"
    - Port: 1025-65535
      Source: EKS Control Plane
      Description: "Kubelet and workload ports"

  Egress:
    - Port: All
      Destination: 0.0.0.0/0
      Description: "All outbound traffic"
```

### 3. Application Load Balancer Security Group

```yaml
Rules:
  Ingress:
    - Port: 80
      Source: 0.0.0.0/0
      Description: "HTTP from internet"
    - Port: 443
      Source: 0.0.0.0/0
      Description: "HTTPS from internet"

  Egress:
    - Port: All
      Destination: EKS Node Security Group
      Description: "To EKS nodes"
```

### 4. Database Security Group

```yaml
Rules:
  Ingress:
    - Port: 5432
      Source: EKS Node Security Group
      Description: "PostgreSQL from EKS"
    - Port: 443
      Source: EKS Node Security Group
      Description: "HTTPS to DynamoDB VPC endpoint"

  Egress:
    - None (default deny)
```

## Network Policies (Kubernetes)

### 1. Default Deny Policy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: observability
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
```

### 2. Grafana Network Policy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: grafana-netpol
  namespace: observability
spec:
  podSelector:
    matchLabels:
      app: grafana
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: ingress-nginx
      ports:
        - protocol: TCP
          port: 3000
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: prometheus
      ports:
        - protocol: TCP
          port: 9090
    - to:
        - podSelector:
            matchLabels:
              app: loki
      ports:
        - protocol: TCP
          port: 3100
    - to: []
      ports:
        - protocol: TCP
          port: 53
        - protocol: UDP
          port: 53
```

### 3. Prometheus Network Policy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: prometheus-netpol
  namespace: observability
spec:
  podSelector:
    matchLabels:
      app: prometheus
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: grafana
        - podSelector:
            matchLabels:
              app: prometheus # For federation
      ports:
        - protocol: TCP
          port: 9090
  egress:
    - to:
        - namespaceSelector: {}
      ports:
        - protocol: TCP
          port: 9100 # Node exporter
        - protocol: TCP
          port: 8080 # Kube-state-metrics
    - to: []
      ports:
        - protocol: TCP
          port: 53
        - protocol: UDP
          port: 53
```

## VPC Endpoints

### 1. S3 VPC Endpoint

```hcl
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.aws_region}.s3"

  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::observability-*",
          "arn:aws:s3:::observability-*/*"
        ]
      }
    ]
  })
}
```

### 2. DynamoDB VPC Endpoint

```hcl
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.aws_region}.dynamodb"

  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:*:table/observability-*"
      }
    ]
  })
}
```

## TLS/SSL Configuration

### 1. In-Transit Encryption

- **External Traffic**: ALB terminates TLS 1.2+ certificates
- **Internal Traffic**: mTLS between services where possible
- **AWS Services**: HTTPS/TLS only for all AWS API calls

### 2. Certificate Management

- **External Certificates**: AWS Certificate Manager (ACM)
- **Internal Certificates**: cert-manager with Let's Encrypt or internal CA
- **Rotation**: Automatic rotation enabled

### 3. TLS Policies

```yaml
# ALB TLS Policy
SecurityPolicy: ELBSecurityPolicy-TLS-1-2-2017-01

# Kubernetes Ingress TLS
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: observability-ingress
  annotations:
    alb.ingress.kubernetes.io/ssl-policy: ELBSecurityPolicy-TLS-1-2-2017-01
    alb.ingress.kubernetes.io/ssl-redirect: "443"
spec:
  tls:
    - hosts:
        - grafana.observability.example.com
      secretName: grafana-tls
```

## WAF (Web Application Firewall) Rules

### 1. AWS WAF Configuration

```yaml
Rules:
  - Name: AWSManagedRulesCommonRuleSet
    Priority: 1
    Statement:
      ManagedRuleGroupStatement:
        VendorName: AWS
        Name: AWSManagedRulesCommonRuleSet

  - Name: AWSManagedRulesKnownBadInputsRuleSet
    Priority: 2
    Statement:
      ManagedRuleGroupStatement:
        VendorName: AWS
        Name: AWSManagedRulesKnownBadInputsRuleSet

  - Name: RateLimitRule
    Priority: 3
    Statement:
      RateBasedStatement:
        Limit: 2000
        AggregateKeyType: IP
```

### 2. Rate Limiting

- **Global Rate Limit**: 2000 requests per 5 minutes per IP
- **Grafana Rate Limit**: 100 requests per minute per user
- **API Rate Limit**: 500 requests per minute per API key

## Network Monitoring

### 1. VPC Flow Logs

```hcl
resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}
```

### 2. Network Monitoring Tools

- **VPC Flow Logs**: All network traffic logged
- **AWS Config**: Network configuration compliance
- **GuardDuty**: Network threat detection
- **CloudTrail**: API call logging

### 3. Prometheus Network Metrics

```yaml
# Network policy violations
- alert: NetworkPolicyViolation
  expr: increase(cilium_policy_verdict_total{verdict="DENIED"}[5m]) > 0
  labels:
    severity: warning
  annotations:
    summary: "Network policy violation detected"

# Unusual traffic patterns
- alert: UnusualNetworkTraffic
  expr: rate(container_network_receive_bytes_total[5m]) > 100000000
  labels:
    severity: warning
  annotations:
    summary: "Unusual network traffic detected"
```

## Compliance and Auditing

### 1. Network Segmentation Compliance

- **PCI DSS**: Separate network segments for sensitive data
- **SOC 2**: Network access controls and monitoring
- **GDPR**: Data flow documentation and controls

### 2. Audit Requirements

- **Network Access Logs**: All network access logged and retained
- **Configuration Changes**: All network changes tracked
- **Compliance Scanning**: Regular network security scans

## Incident Response

### 1. Network Security Incidents

```yaml
Severity Levels:
  Critical:
    - Data exfiltration detected
    - Unauthorized external access
    - Lateral movement detected

  High:
    - Network policy violations
    - Unusual traffic patterns
    - Failed connection attempts

  Medium:
    - Configuration drift
    - Certificate expiration warnings
    - Performance anomalies
```

### 2. Response Procedures

1. **Immediate**: Isolate affected resources
2. **Investigate**: Analyze network logs and traffic
3. **Contain**: Apply additional network restrictions
4. **Remediate**: Fix vulnerabilities and update policies
5. **Document**: Update runbooks and procedures

## Network Security Checklist

### Initial Setup

- [ ] VPC and subnets configured with proper CIDR blocks
- [ ] Security groups configured with least privilege
- [ ] Network policies deployed for pod-to-pod communication
- [ ] VPC endpoints configured for AWS services
- [ ] WAF rules enabled for public endpoints

### Ongoing Maintenance

- [ ] Regular security group audits
- [ ] Network policy testing and validation
- [ ] Certificate rotation monitoring
- [ ] Network traffic analysis
- [ ] Compliance scanning and reporting

### Monitoring and Alerting

- [ ] VPC Flow Logs enabled and monitored
- [ ] Network policy violation alerts configured
- [ ] Unusual traffic pattern detection
- [ ] Certificate expiration monitoring
- [ ] Network performance monitoring
