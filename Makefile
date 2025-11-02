# Observability Platform - Comprehensive Makefile
# ==================================================
# This Makefile provides all CI/CD operations for the observability platform
#
# Quick Start:
#   make setup     - Setup CI environment and tools
#   make ci        - Run full CI pipeline
#   make lint      - Run all linters
#   make security  - Run security scans
#   make validate  - Validate infrastructure
#   make clean     - Cleanup artifacts

.DEFAULT_GOAL := help
.PHONY: help setup clean lint security validate test ci deploy status

# Configuration
PROJECT_ROOT := $(shell pwd)
CI_DIR := $(PROJECT_ROOT)/ci
REPORTS_DIR := $(PROJECT_ROOT)/.reports
TERRAFORM_DIR := $(PROJECT_ROOT)/terraform
K8S_DIR := $(PROJECT_ROOT)/k8s

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Helper function to print colored output
define print_section
	@echo "$(BLUE)========================================$(NC)"
	@echo "$(BLUE)$(1)$(NC)"
	@echo "$(BLUE)========================================$(NC)"
endef

define print_success
	@echo "$(GREEN)✅ $(1)$(NC)"
endef

define print_warning
	@echo "$(YELLOW)⚠️  $(1)$(NC)"
endef

define print_error
	@echo "$(RED)❌ $(1)$(NC)"
endef

## help: Show this help message
help:
	@echo "Observability Platform - CI/CD Operations"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Setup Commands:"
	@echo "  setup          Setup CI environment and install all tools"
	@echo "  verify         Verify all tools are installed correctly"
	@echo ""
	@echo "Development Commands:"
	@echo "  lint           Run all linting checks"
	@echo "  validate       Validate infrastructure configurations"
	@echo "  test           Run all tests (policies, validation, etc.)"
	@echo "  format         Format all code files"
	@echo ""
	@echo "CI/CD Commands:"
	@echo "  ci             Run complete CI pipeline"
	@echo "  pre-commit     Setup and run pre-commit hooks"
	@echo "  quality-gates  Run lightweight dependency vulnerability checks (FAST)"
	@echo ""
	@echo "Security Commands (Deep Analysis):"
	@echo "  security              Run all comprehensive security scans (SLOW)"
	@echo "  scan-infrastructure   Deep IaC security analysis (checkov + tfsec)"
	@echo "  scan-containers      Deep container vulnerability analysis (trivy)"
	@echo "  scan-dependencies    Lightweight dependency vulnerability check (quality gate)"
	@echo ""
	@echo "Infrastructure Commands:"
	@echo "  tf-plan        Run Terraform plan for all environments"
	@echo "  tf-validate    Validate all Terraform configurations"
	@echo "  k8s-validate   Validate all Kubernetes manifests"
	@echo "  k8s-build      Build Kustomize manifests"
	@echo ""
	@echo "Deployment Commands:"
	@echo "  deploy-dev     Deploy to development environment"
	@echo "  deploy-prod    Deploy to production environment"
	@echo ""
	@echo "Maintenance Commands:"
	@echo "  clean          Clean all temporary files and artifacts"
	@echo "  clean-reports  Clean only report files"
	@echo "  status         Show project and tool status"
	@echo ""

## setup: Setup CI environment and install all required tools
setup:
	$(call print_section,Setting up CI environment)
	@chmod +x $(CI_DIR)/scripts/setup-tools.sh
	@$(CI_DIR)/scripts/setup-tools.sh
	$(call print_success,CI environment setup completed)

## verify: Verify all tools are installed and working
verify:
	$(call print_section,Verifying CI tools installation)
	@echo "Checking required tools..."
	@command -v kubectl >/dev/null 2>&1 && echo "✅ kubectl" || echo "❌ kubectl"
	@command -v kustomize >/dev/null 2>&1 && echo "✅ kustomize" || echo "❌ kustomize"
	@command -v terraform >/dev/null 2>&1 && echo "✅ terraform" || echo "❌ terraform"
	@command -v tfsec >/dev/null 2>&1 && echo "✅ tfsec" || echo "❌ tfsec"
	@command -v trivy >/dev/null 2>&1 && echo "✅ trivy" || echo "❌ trivy"
	@command -v conftest >/dev/null 2>&1 && echo "✅ conftest" || echo "❌ conftest"
	@command -v checkov >/dev/null 2>&1 && echo "✅ checkov" || echo "❌ checkov"
	@command -v yamllint >/dev/null 2>&1 && echo "✅ yamllint" || echo "❌ yamllint"
	@command -v markdownlint >/dev/null 2>&1 && echo "✅ markdownlint" || echo "❌ markdownlint"
	@command -v pre-commit >/dev/null 2>&1 && echo "✅ pre-commit" || echo "❌ pre-commit"
	$(call print_success,Tool verification completed)

## lint: Run all linting checks
lint: lint-yaml lint-markdown lint-json
	$(call print_success,All linting completed)

## lint-yaml: Run YAML linting
lint-yaml:
	$(call print_section,Running YAML linting)
	@chmod +x $(CI_DIR)/lint/lint-yaml.sh
	@$(CI_DIR)/lint/lint-yaml.sh

## lint-markdown: Run Markdown linting
lint-markdown:
	$(call print_section,Running Markdown linting)
	@chmod +x $(CI_DIR)/lint/lint-markdown.sh
	@$(CI_DIR)/lint/lint-markdown.sh

## lint-json: Run JSON linting
lint-json:
	$(call print_section,Running JSON linting)
	@chmod +x $(CI_DIR)/lint/lint-json.sh
	@$(CI_DIR)/lint/lint-json.sh

## format: Format all code files
format:
	$(call print_section,Formatting code files)
	@echo "Formatting Terraform files..."
	@find $(TERRAFORM_DIR) -name "*.tf" -exec terraform fmt {} \; 2>/dev/null || true
	@echo "Formatting YAML files..."
	@find $(K8S_DIR) -name "*.yaml" -o -name "*.yml" | head -20 | xargs -I {} sh -c 'yq eval "." {} > /tmp/formatted.yaml && mv /tmp/formatted.yaml {}' 2>/dev/null || true
	$(call print_success,Code formatting completed)

## security: Run comprehensive security scans (deep analysis - slower)
security: scan-infrastructure scan-containers
	$(call print_success,Comprehensive security analysis completed)
	@echo ""
	@echo "📊 Security Scan Summary:"
	@echo "  🏗️  Infrastructure Security: $(REPORTS_DIR)/security/checkov-*.json"
	@echo "  🐳 Container Security: $(REPORTS_DIR)/security/trivy-*.json"
	@echo "  📋 Detailed reports available in $(REPORTS_DIR)/security/"

## scan-infrastructure: Run infrastructure security scanning
scan-infrastructure:
	$(call print_section,Running infrastructure security scans)
	@chmod +x $(CI_DIR)/security/checkov/run-checkov.sh
	@$(CI_DIR)/security/checkov/run-checkov.sh
	@chmod +x $(CI_DIR)/tf-tests/run-tfsec.sh
	@$(CI_DIR)/tf-tests/run-tfsec.sh

## scan-containers: Run container security scanning
scan-containers:
	$(call print_section,Running container security scans)
	@chmod +x $(CI_DIR)/security/trivy/scan-containers.sh
	@$(CI_DIR)/security/trivy/scan-containers.sh

## scan-dependencies: Run dependency security scanning
scan-dependencies:
	$(call print_section,Running dependency security scans)
	@chmod +x $(CI_DIR)/quality-gates/dependency-check.sh
	@$(CI_DIR)/quality-gates/dependency-check.sh

## validate: Validate all infrastructure configurations
validate: tf-validate k8s-validate
	$(call print_success,All validation completed)

## tf-validate: Validate Terraform configurations
tf-validate:
	$(call print_section,Validating Terraform configurations)
	@chmod +x $(CI_DIR)/validation/terraform-validate.sh
	@$(CI_DIR)/validation/terraform-validate.sh

## k8s-validate: Validate Kubernetes manifests
k8s-validate:
	$(call print_section,Validating Kubernetes manifests)
	@chmod +x $(CI_DIR)/validation/kustomize-validate.sh
	@$(CI_DIR)/validation/kustomize-validate.sh

## k8s-build: Build Kustomize manifests
k8s-build:
	$(call print_section,Building Kustomize manifests)
	@mkdir -p $(REPORTS_DIR)/kustomize
	@find $(K8S_DIR) -name "kustomization.yaml" -exec dirname {} \; | while read dir; do \
		rel_path=$$(realpath --relative-to="$(PROJECT_ROOT)" "$$dir"); \
		echo "Building: $$rel_path"; \
		kubectl kustomize "$$dir" > "$(REPORTS_DIR)/kustomize/$$(echo $$rel_path | tr '/' '_').yaml" 2>/dev/null || echo "Failed: $$rel_path"; \
	done
	$(call print_success,Kustomize builds completed)

## test: Run all tests
test: test-policies test-validation
	$(call print_success,All tests completed)

## test-policies: Run OPA policy tests
test-policies:
	$(call print_section,Running OPA policy tests)
	@chmod +x $(CI_DIR)/policy-tests/test-policies.sh
	@$(CI_DIR)/policy-tests/test-policies.sh

## test-validation: Run validation tests
test-validation: validate
	@echo "Validation tests completed as part of validate target"

## quality-gates: Run lightweight quality gate checks (fast dependency scanning)
quality-gates:
	$(call print_section,Running quality gate checks (Fast))
	@make scan-dependencies
	@echo ""
	@echo "🚦 Quality Gate Results:"
	@echo "  📊 Dependency Vulnerabilities: $(REPORTS_DIR)/dependencies/"
	@echo "  ⚡ Fast execution for CI/CD pipeline integration"
	@echo "  🔍 For deep security analysis, run 'make security'"

## tf-plan: Run Terraform plan for all environments
tf-plan:
	$(call print_section,Running Terraform plans)
	@for env_dir in $(TERRAFORM_DIR)/envs/*; do \
		if [ -d "$$env_dir" ]; then \
			env_name=$$(basename "$$env_dir"); \
			echo "Planning environment: $$env_name"; \
			cd "$$env_dir" && terraform init -backend=false >/dev/null 2>&1 || true; \
			if [ -f "terraform.tfvars" ]; then \
				terraform plan -var-file=terraform.tfvars -out="terraform.plan" || echo "Plan failed for $$env_name"; \
			elif [ -f "terraform.tfvars.example" ]; then \
				terraform plan -var-file=terraform.tfvars.example -out="terraform.plan" || echo "Plan failed for $$env_name"; \
			else \
				terraform plan -out="terraform.plan" || echo "Plan failed for $$env_name"; \
			fi; \
			rm -f terraform.plan; \
			cd "$(PROJECT_ROOT)"; \
		fi; \
	done
	$(call print_success,Terraform planning completed)

## pre-commit: Setup and run pre-commit hooks
pre-commit:
	$(call print_section,Setting up pre-commit hooks)
	@if command -v pre-commit >/dev/null 2>&1; then \
		pre-commit install; \
		echo "Running pre-commit on all files..."; \
		pre-commit run --all-files; \
	else \
		echo "❌ pre-commit not installed. Run 'make setup' first."; \
		exit 1; \
	fi
	$(call print_success,Pre-commit setup completed)

## ci: Run complete CI pipeline
ci: lint security validate test quality-gates
	$(call print_section,CI Pipeline Summary)
	@echo "CI Pipeline completed. Check results:"
	@echo "- Reports directory: $(REPORTS_DIR)"
	@echo "- Security scans: $(REPORTS_DIR)/security/"
	@echo "- Validation results: $(REPORTS_DIR)/validation/"
	@echo "- Policy tests: $(REPORTS_DIR)/policy/"
	@echo "- Dependencies: $(REPORTS_DIR)/dependencies/"
	$(call print_success,Complete CI pipeline finished)

## deploy-dev: Deploy to development environment
deploy-dev:
	$(call print_section,Deploying to development environment)
	@echo "⚠️  Manual deployment process:"
	@echo "1. Ensure kubectl is configured for dev cluster"
	@echo "2. Apply Terraform: cd terraform/envs/dev && terraform apply"
	@echo "3. Deploy K8s: kubectl apply -k k8s/overlays/dev"
	@echo "4. Verify deployment: make status"
	$(call print_warning,Manual deployment steps listed above)

## deploy-prod: Deploy to production environment
deploy-prod:
	$(call print_section,Deploying to production environment)
	@echo "⚠️  Production deployment requires manual approval:"
	@echo "1. Run full CI: make ci"
	@echo "2. Review all reports in $(REPORTS_DIR)"
	@echo "3. Get deployment approval"
	@echo "4. Apply Terraform: cd terraform/envs/prod && terraform apply"
	@echo "5. Deploy K8s: kubectl apply -k k8s/overlays/prod"
	@echo "6. Run post-deployment validation"
	$(call print_warning,Production deployment requires manual steps)

## status: Show project and environment status
status:
	$(call print_section,Project Status)
	@echo "Project: Observability Platform"
	@echo "Location: $(PROJECT_ROOT)"
	@echo ""
	@echo "Git Status:"
	@git status --porcelain | head -10 || echo "Not a git repository"
	@echo ""
	@echo "Recent Reports:"
	@ls -la $(REPORTS_DIR)/ 2>/dev/null | head -10 || echo "No reports directory"
	@echo ""
	@echo "CI Tools Status:"
	@make verify 2>/dev/null | grep -E "(✅|❌)" | head -10
	@echo ""
	@echo "Environment Files:"
	@ls -la terraform/envs/ 2>/dev/null || echo "No terraform environments"
	@echo ""
	@echo "Kubernetes Resources:"
	@find k8s/ -name "kustomization.yaml" | wc -l | xargs echo "Kustomization files:"

## clean: Clean all temporary files and artifacts
clean:
	$(call print_section,Cleaning up CI artifacts)
	@chmod +x $(CI_DIR)/scripts/cleanup.sh
	@$(CI_DIR)/scripts/cleanup.sh

## clean-reports: Clean only report files
clean-reports:
	$(call print_section,Cleaning report files)
	@rm -rf $(REPORTS_DIR)/*
	@mkdir -p $(REPORTS_DIR)/{security,validation,policy,dependencies}
	$(call print_success,Report files cleaned)

# Internal targets (not shown in help)
.PHONY: _create_dirs _check_tools

_create_dirs:
	@mkdir -p $(REPORTS_DIR)/{security,validation,policy,dependencies}

_check_tools:
	@command -v kubectl >/dev/null 2>&1 || (echo "❌ kubectl not found. Run 'make setup'"; exit 1)
	@command -v terraform >/dev/null 2>&1 || (echo "❌ terraform not found. Run 'make setup'"; exit 1)

# Make all scripts executable when needed
$(CI_DIR)/%:
	@chmod +x $@

# Ensure reports directory exists for all targets that need it
security validate test quality-gates: _create_dirs

# Add dependency checking for main targets
ci: _check_tools
validate: _check_tools
security: _check_tools
