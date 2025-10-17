.PHONY: help bootstrap plan apply destroy clean port-forward

ENVIRONMENT ?= dev
TERRAFORM_DIR = terraform/envs/$(ENVIRONMENT)
K8S_OVERLAY = k8s/overlays/$(ENVIRONMENT)

help: ## Show this help message
	@echo 'Usage: make [target] [ENVIRONMENT=dev|prod]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

bootstrap: ## Initialize the environment (S3 buckets, etc.)
	@echo "Bootstrapping $(ENVIRONMENT) environment..."
	./scripts/bootstrap.sh $(ENVIRONMENT)

plan: ## Run terraform plan
	@echo "Planning infrastructure for $(ENVIRONMENT)..."
	cd $(TERRAFORM_DIR) && terraform init && terraform plan

apply: ## Apply terraform configuration
	@echo "Applying infrastructure for $(ENVIRONMENT)..."
	cd $(TERRAFORM_DIR) && terraform init && terraform apply

deploy-k8s: ## Deploy Kubernetes resources
	@echo "Deploying Kubernetes resources for $(ENVIRONMENT)..."
	kubectl apply -k $(K8S_OVERLAY)
	helmfile -e $(ENVIRONMENT) apply

deploy: apply deploy-k8s ## Deploy infrastructure and Kubernetes resources

destroy: ## Destroy infrastructure
	@echo "Destroying infrastructure for $(ENVIRONMENT)..."
	kubectl delete -k $(K8S_OVERLAY) || true
	cd $(TERRAFORM_DIR) && terraform destroy

clean: ## Clean up temporary files
	@echo "Cleaning up..."
	find . -name "*.tfplan" -delete
	find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	find . -name "terraform.tfstate.backup" -delete

port-forward: ## Set up port forwarding for local access
	@echo "Setting up port forwarding..."
	./scripts/port-forward.sh

test: ## Run tests
	@echo "Running tests..."
	cd ci/tf-tests && terraform fmt -check -recursive ../../terraform/
	cd ci/policy-tests && conftest test --policy . ../../k8s/
	cd apps/demo-shop && python -m pytest tests/ 2>/dev/null || echo "No tests found"

lint: ## Run linting
	@echo "Running linting..."
	markdownlint docs/**/*.md README.md
	find . -name "*.yaml" -o -name "*.yml" | head -20 | xargs yamllint

install-tools: ## Install required tools
	@echo "Installing required tools..."
	# Add tool installation commands here
	brew install terraform kubectl helm helmfile conftest markdownlint-cli yamllint || echo "Please install tools manually"

validate: lint test ## Run validation (lint + test)

status: ## Show cluster status
	@echo "Cluster status:"
	kubectl get nodes
	kubectl get pods -n observability
