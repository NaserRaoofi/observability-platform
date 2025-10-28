# Dashboard Organization Structure

This directory contains Grafana dashboards organized by functional categories for better maintainability and clarity.

## 📁 Folder Structure

```
dashboards/
├── main.tf           # Central module coordinator
├── infra/            # Infrastructure monitoring dashboards
│   ├── main.tf
│   ├── variables.tf
│   └── alertmanager-overview.tf
├── slo/              # Service Level Objective dashboards  
│   ├── main.tf
│   ├── variables.tf
│   └── slo-monitoring.tf
├── app/              # Application-specific dashboards
│   ├── main.tf
│   └── variables.tf
└── sre/              # SRE operational dashboards
    ├── main.tf
    └── variables.tf
```

## 🎯 Dashboard Categories

### Infrastructure (`infra/`)
**Purpose**: Monitor core infrastructure components and services
**Grafana Folder**: "Infrastructure Monitoring" 
**Current Dashboards**:
- **AlertManager Overview**: Comprehensive AlertManager monitoring with alerts, notifications, and cluster status

**Planned Dashboards**:
- Kubernetes cluster health
- Node resource utilization  
- Network performance metrics
- Storage and disk usage

### SLO (`slo/`)
**Purpose**: Track Service Level Objectives and error budgets
**Grafana Folder**: "SLO Monitoring"
**Current Dashboards**:
- **SLO Monitoring**: Error budget tracking, burn rates, and SLO alert integration

**Planned Dashboards**:
- Service-specific SLO tracking
- Multi-service SLO overview
- Historical SLO performance trends

### Applications (`app/`)
**Purpose**: Monitor application-specific metrics and performance
**Grafana Folder**: "Application Monitoring"  
**Status**: Placeholder ready for application dashboards

**Planned Dashboards**:
- API response times and error rates
- Database performance and query metrics
- Message queue monitoring
- User journey and business metrics
- Application-specific KPIs

### SRE (`sre/`)
**Purpose**: Site Reliability Engineering operational dashboards  
**Grafana Folder**: "SRE Operations"
**Status**: Placeholder ready for SRE dashboards

**Planned Dashboards**:
- Incident response metrics
- Change failure rates
- Mean Time to Recovery (MTTR)
- Deployment frequency tracking
- Cross-service reliability metrics

## 🔧 Benefits of This Structure

### 1. **Clear Separation of Concerns**
- Each category has its own folder and module
- Easy to find relevant dashboards
- Reduces cognitive load when managing dashboards

### 2. **Scalable Organization**
- Easy to add new dashboards to appropriate categories
- Can assign different teams to different categories
- Clear ownership and responsibility

### 3. **Modular Terraform Structure**
- Each category is an independent Terraform module
- Can enable/disable categories as needed
- Better resource management and dependencies

### 4. **Team-Oriented**
- **Infrastructure Team**: Focus on `infra/` dashboards
- **Product Teams**: Focus on `app/` dashboards  
- **SRE Team**: Focus on `sre/` and `slo/` dashboards
- **Platform Team**: Manage overall structure

## 🚀 Adding New Dashboards

### To Infrastructure Category:
```bash
# Create new dashboard file
vim terraform/modules/grafana/dashboards/infra/kubernetes-cluster.tf

# Add output to infra/main.tf
output "kubernetes_dashboard_uid" { ... }
```

### To Application Category:
```bash
# Create new dashboard file  
vim terraform/modules/grafana/dashboards/app/api-performance.tf

# Update app/main.tf outputs
```

### New Category:
```bash
# Create new category directory
mkdir terraform/modules/grafana/dashboards/security/

# Create module files
touch terraform/modules/grafana/dashboards/security/{main.tf,variables.tf}

# Add module to main dashboards/main.tf
module "security_dashboards" { ... }
```

## 📊 Dashboard Development Workflow

1. **Identify Category**: Determine which folder the dashboard belongs to
2. **Create Dashboard File**: Add `.tf` file in appropriate category folder  
3. **Update Module Outputs**: Add dashboard UID to category's `main.tf`
4. **Update Main Module**: Ensure outputs are propagated up
5. **Test & Deploy**: Use `terraform plan` and `terraform apply`

This organization matches the clean structure you showed in your screenshot, making it much easier to manage dashboards as your observability platform grows! 🎉