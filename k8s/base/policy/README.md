# Security Policies for Observability Platform

This directory contains security policies to harden the observability platform according to enterprise security standards.

## Components

### **Network Policies** (`network-policies.yaml`)

- Restrict inter-pod communication to required connections only
- Allow only necessary ingress/egress traffic
- Isolate observability namespace from other workloads

### **Pod Security Standards** (`pod-security-policies.yaml`)

- Enforce security contexts and privilege restrictions
- Require non-root containers where possible
- Restrict filesystem mounts and capabilities

### **RBAC Policies** (`rbac.yaml`)

- Service accounts with minimal required permissions
- Role-based access control for observability components
- Kubernetes API access restrictions

### **OPA Gatekeeper Policies** (`gatekeeper-policies.yaml`)

- Custom admission control policies
- Resource quotas and limits enforcement
- Security compliance validation

### **Resource Management Policies** (`resource-policies.yaml`)

- Resource quotas and limit ranges
- Priority classes for workload scheduling
- Pod disruption budgets for high availability
- Horizontal pod autoscaler configurations

## Security Architecture

### **Defense in Depth Model**

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           ENTERPRISE SECURITY ARCHITECTURE                          │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Network Layer  │    │   Pod Layer     │    │   API Layer     │    │ Resource Layer  │
│                 │    │                 │    │                 │    │                 │
│ • NetworkPolicy │───▶│ • PSP/PSS       │───▶│ • RBAC          │───▶│ • ResourceQuota │
│ • Ingress Rules │    │ • SecurityCtx   │    │ • Least Privs   │    │ • LimitRange    │
│ • Egress Rules  │    │ • Non-root      │    │ • Service Accts │    │ • PriorityClass │
│ • Micro-segment │    │ • ReadOnly FS   │    │ • ClusterRoles  │    │ • PDB/HPA       │
└─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
        │                       │                       │                       │
        ▼                       ▼                       ▼                       ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              ADMISSION CONTROL                                      │
│                                                                                     │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐                │
│  │ OPA Gatekeeper  │    │ Pod Security    │    │  Image Policy   │                │
│  │                 │    │   Standards     │    │                 │                │
│  │ • Resource Req  │    │ • Restricted    │    │ • Allowed Regs  │                │
│  │ • Label Policy  │    │ • Baseline      │    │ • Vuln Scanning │                │
│  │ • Security Ctx  │    │ • Privileged    │    │ • Image Signing │                │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘                │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### **Component Security Matrix**

```
                        Network    Pod       RBAC      Resource   OPA
Component               Policy     Security  Access    Limits     Policy
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
OTel Collector Agent    ✅ Strict  ✅ Host   ✅ K8s     ✅ High    ✅ Yes
OTel Collector Gateway  ✅ Strict  ✅ Restr  ✅ Min     ✅ Med     ✅ Yes
Mimir Components        ✅ Strict  ✅ Restr  ✅ None    ✅ High    ✅ Yes
Loki Components         ✅ Strict  ✅ Restr  ✅ None    ✅ High    ✅ Yes
Tempo Components        ✅ Strict  ✅ Restr  ✅ None    ✅ Med     ✅ Yes
Grafana                 ✅ Strict  ✅ Restr  ✅ None    ✅ Low     ✅ Yes
Node Exporter           ✅ Host    ✅ Host   ✅ None    ✅ Low     ✅ Exempt
Kube State Metrics      ✅ Strict  ✅ Restr  ✅ K8s     ✅ Low     ✅ Yes
Blackbox Exporter       ✅ Strict  ✅ Restr  ✅ None    ✅ Low     ✅ Yes
Other Exporters         ✅ Strict  ✅ Restr  ✅ Cloud   ✅ Low     ✅ Yes
Sloth                   ✅ Strict  ✅ Restr  ✅ K8s     ✅ Low     ✅ Yes
```

### **Traffic Flow Security**

```
External Apps                 Observability Namespace                    Cloud Storage
     │                               │                                        │
     ▼                               ▼                                        ▼
┌─────────┐    NetworkPolicy    ┌─────────┐    IRSA/IAM     ┌─────────────────┐
│ Apps/   │ ──── Ingress ────▶ │ OTel    │ ──── HTTPS ───▶ │ S3 Buckets      │
│ Users   │     (4317/4318)    │ Gateway │     (443)       │ DynamoDB Tables │
└─────────┘                    └─────────┘                 └─────────────────┘
     │                               │
     ▼          NetworkPolicy        ▼        NetworkPolicy
┌─────────┐ ──── 14268/9411 ─── ┌─────────┐ ──── 8080 ──── ┌─────────┐
│ Legacy  │                    │ OTel    │                 │ Mimir   │
│ Apps    │                    │ Agent   │                 │ Cluster │
└─────────┘                    └─────────┘                 └─────────┘
                                    │
                   NetworkPolicy    │        NetworkPolicy
                                    ▼
                               ┌─────────┐ ──── 3100 ──── ┌─────────┐
                               │ File    │                 │ Loki    │
                               │ Logs    │                 │ Cluster │
                               └─────────┘                 └─────────┘
                                    │
                   NetworkPolicy    │        NetworkPolicy
                                    ▼
                               ┌─────────┐ ──── 4317 ──── ┌─────────┐
                               │ Host    │                 │ Tempo   │
                               │ Metrics │                 │ Cluster │
                               └─────────┘                 └─────────┘
```

### **Security Zones**

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                DMZ ZONE                                             │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐                │
│  │    Grafana      │    │  External LB    │    │   Ingress      │                │
│  │   (UI Access)   │    │ (Public Facing) │    │  Controller    │                │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘                │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                      │
                        Strict NetworkPolicy
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           PROCESSING ZONE                                          │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐                │
│  │ OTel Collector  │    │ OTel Collector  │    │   Exporters     │                │
│  │    Gateway      │    │     Agent       │    │   (Metrics)     │                │
│  │  (Deployment)   │    │  (DaemonSet)    │    │                 │                │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘                │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                      │
                        Strict NetworkPolicy
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                            STORAGE ZONE                                            │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐                │
│  │     Mimir       │    │      Loki       │    │     Tempo       │                │
│  │  (Long-term     │    │ (Log Storage &  │    │  (Trace         │                │
│  │   Metrics)      │    │   Search)       │    │   Storage)      │                │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘                │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                      │
                          AWS IAM/IRSA
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                             CLOUD ZONE                                             │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐                │
│  │   S3 Buckets    │    │ DynamoDB Tables │    │   KMS Keys      │                │
│  │ (Encrypted at   │    │   (Indexes)     │    │ (Encryption)    │                │
│  │    Rest)        │    │                 │    │                 │                │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘                │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Security Principles

### **Defense in Depth**

- Multiple layers of security controls
- Network segmentation with NetworkPolicies
- Pod-level security with PodSecurityStandards
- API access control with RBAC

### **Least Privilege**

- Minimal required permissions for each component
- Non-root containers where possible
- Restricted filesystem access
- Limited network connectivity

### **Compliance**

- CIS Kubernetes Benchmark alignment
- SOC 2 security controls
- GDPR data protection considerations
- Industry best practices

## Implementation

Deploy security policies before observability components:

```bash
# Apply all security policies
kubectl apply -f k8s/base/policy/

# Verify policies are active
kubectl get networkpolicies -n observability
kubectl get podsecuritypolicy
kubectl get clusterroles,roles -n observability
```

## Validation

Use security scanning tools to validate policy effectiveness:

```bash
# Scan with kube-bench (CIS compliance)
kube-bench run

# Scan with kube-hunter (security issues)
kube-hunter --remote

# Policy validation with OPA
opa test policies/
```
