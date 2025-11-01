#!/bin/bash

set -euo pipefail

# Terraform Infrastructure Validation
echo "🏗️ Running Terraform validation..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to check terraform installation
check_terraform() {
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}❌ Terraform not found. Please install Terraform.${NC}"
        exit 1
    fi

    local tf_version=$(terraform version -json | jq -r '.terraform_version')
    echo -e "${BLUE}Using Terraform version: $tf_version${NC}"
}

# Function to validate terraform formatting
validate_format() {
    echo -e "${BLUE}📝 Checking Terraform formatting...${NC}"

    local terraform_dirs=$(find "$PROJECT_ROOT/terraform" -type d -name ".terraform" -prune -o -name "*.tf" -print | sed 's|/[^/]*\.tf$||' | sort -u)

    local format_issues=0

    while IFS= read -r dir; do
        if [ -n "$dir" ]; then
            echo -e "${BLUE}Checking format in: $dir${NC}"

            cd "$dir"
            if ! terraform fmt -check -recursive .; then
                echo -e "${RED}❌ Formatting issues found in: $dir${NC}"
                echo -e "${YELLOW}Run 'terraform fmt -recursive .' to fix${NC}"
                format_issues=1
            else
                echo -e "${GREEN}✅ Formatting is correct in: $dir${NC}"
            fi
        fi
    done <<< "$terraform_dirs"

    return $format_issues
}

# Function to validate terraform syntax
validate_syntax() {
    echo -e "${BLUE}🔍 Validating Terraform syntax...${NC}"

    local terraform_dirs=$(find "$PROJECT_ROOT/terraform" -name "*.tf" -exec dirname {} \; | sort -u)

    local validation_issues=0

    while IFS= read -r dir; do
        if [ -n "$dir" ]; then
            echo -e "${BLUE}Validating: $dir${NC}"

            cd "$dir"

            # Initialize if needed (skip provider downloads for validation)
            if [ ! -d ".terraform" ]; then
                if ! terraform init -backend=false -upgrade=false; then
                    echo -e "${RED}❌ Failed to initialize: $dir${NC}"
                    validation_issues=1
                    continue
                fi
            fi

            # Validate
            if terraform validate; then
                echo -e "${GREEN}✅ Validation passed: $dir${NC}"
            else
                echo -e "${RED}❌ Validation failed: $dir${NC}"
                validation_issues=1
            fi
        fi
    done <<< "$terraform_dirs"

    return $validation_issues
}

# Function to check for terraform plan
validate_plan() {
    echo -e "${BLUE}📋 Checking Terraform plan (dry-run)...${NC}"

    local env_dirs=$(find "$PROJECT_ROOT/terraform/envs" -maxdepth 1 -type d | grep -v "^$PROJECT_ROOT/terraform/envs$")

    if [ -z "$env_dirs" ]; then
        echo -e "${YELLOW}⚠️  No environment directories found${NC}"
        return 0
    fi

    local plan_issues=0

    while IFS= read -r env_dir; do
        if [ -n "$env_dir" ]; then
            local env_name=$(basename "$env_dir")
            echo -e "${BLUE}Planning for environment: $env_name${NC}"

            cd "$env_dir"

            # Check for terraform.tfvars or terraform.tfvars.example
            local vars_file=""
            if [ -f "terraform.tfvars" ]; then
                vars_file="terraform.tfvars"
            elif [ -f "terraform.tfvars.example" ]; then
                vars_file="terraform.tfvars.example"
                echo -e "${YELLOW}⚠️  Using example vars file for planning${NC}"
            fi

            # Initialize if needed
            if [ ! -d ".terraform" ]; then
                echo -e "${BLUE}Initializing Terraform for $env_name...${NC}"
                if ! terraform init -backend=false; then
                    echo -e "${RED}❌ Failed to initialize: $env_name${NC}"
                    plan_issues=1
                    continue
                fi
            fi

            # Create plan
            local plan_args=""
            if [ -n "$vars_file" ]; then
                plan_args="-var-file=$vars_file"
            fi

            if terraform plan $plan_args -out="terraform.plan" -detailed-exitcode; then
                local exit_code=$?
                case $exit_code in
                    0)
                        echo -e "${GREEN}✅ Plan succeeded (no changes): $env_name${NC}"
                        ;;
                    2)
                        echo -e "${GREEN}✅ Plan succeeded (changes found): $env_name${NC}"
                        ;;
                esac
            else
                echo -e "${RED}❌ Plan failed: $env_name${NC}"
                plan_issues=1
            fi

            # Clean up plan file
            rm -f terraform.plan
        fi
    done <<< "$env_dirs"

    return $plan_issues
}

# Function to check for security issues
validate_security() {
    echo -e "${BLUE}🔒 Running security validation...${NC}"

    # Use existing tfsec script
    local tfsec_script="$PROJECT_ROOT/ci/tf-tests/run-tfsec.sh"

    if [ -f "$tfsec_script" ]; then
        if bash "$tfsec_script"; then
            echo -e "${GREEN}✅ Security validation passed${NC}"
            return 0
        else
            echo -e "${RED}❌ Security validation failed${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  Security script not found: $tfsec_script${NC}"
        return 0
    fi
}

# Function to check module dependencies
validate_modules() {
    echo -e "${BLUE}📦 Validating Terraform modules...${NC}"

    local module_dirs=$(find "$PROJECT_ROOT/terraform/modules" -maxdepth 1 -type d | grep -v "^$PROJECT_ROOT/terraform/modules$")

    if [ -z "$module_dirs" ]; then
        echo -e "${YELLOW}⚠️  No modules found${NC}"
        return 0
    fi

    local module_issues=0

    while IFS= read -r module_dir; do
        if [ -n "$module_dir" ]; then
            local module_name=$(basename "$module_dir")
            echo -e "${BLUE}Validating module: $module_name${NC}"

            cd "$module_dir"

            # Check required files
            local required_files=("main.tf" "variables.tf" "outputs.tf")
            for file in "${required_files[@]}"; do
                if [ ! -f "$file" ]; then
                    echo -e "${RED}❌ Missing required file: $file in module $module_name${NC}"
                    module_issues=1
                fi
            done

            # Check for README
            if [ ! -f "README.md" ]; then
                echo -e "${YELLOW}⚠️  Missing README.md in module $module_name${NC}"
            fi

            # Validate module syntax
            if terraform init -backend=false && terraform validate; then
                echo -e "${GREEN}✅ Module validation passed: $module_name${NC}"
            else
                echo -e "${RED}❌ Module validation failed: $module_name${NC}"
                module_issues=1
            fi
        fi
    done <<< "$module_dirs"

    return $module_issues
}

# Generate validation report
generate_report() {
    local reports_dir="$PROJECT_ROOT/.reports/validation"
    mkdir -p "$reports_dir"

    local report_file="$reports_dir/terraform-validation.txt"

    {
        echo "Terraform Validation Report"
        echo "=========================="
        echo "Date: $(date)"
        echo "Project: observability-platform"
        echo ""
        echo "Validation Summary:"
        echo "  ✅ Format check: $1"
        echo "  ✅ Syntax check: $2"
        echo "  ✅ Plan check: $3"
        echo "  ✅ Security check: $4"
        echo "  ✅ Module check: $5"
        echo ""
    } > "$report_file"

    echo -e "${BLUE}📊 Validation report saved to: $report_file${NC}"
}

# Main execution
main() {
    cd "$PROJECT_ROOT"

    echo -e "${BLUE}Starting Terraform validation...${NC}"
    echo "Project: $PROJECT_ROOT"
    echo ""

    check_terraform

    local overall_exit=0
    local format_result="PASSED"
    local syntax_result="PASSED"
    local plan_result="PASSED"
    local security_result="PASSED"
    local module_result="PASSED"

    # Run validations
    if ! validate_format; then
        overall_exit=1
        format_result="FAILED"
    fi
    echo ""

    if ! validate_syntax; then
        overall_exit=1
        syntax_result="FAILED"
    fi
    echo ""

    if ! validate_modules; then
        overall_exit=1
        module_result="FAILED"
    fi
    echo ""

    if ! validate_plan; then
        overall_exit=1
        plan_result="FAILED"
    fi
    echo ""

    if ! validate_security; then
        overall_exit=1
        security_result="FAILED"
    fi
    echo ""

    # Generate report
    generate_report "$format_result" "$syntax_result" "$plan_result" "$security_result" "$module_result"

    # Final result
    if [ $overall_exit -eq 0 ]; then
        echo -e "${GREEN}✅ All Terraform validations passed${NC}"
    else
        echo -e "${RED}❌ Some Terraform validations failed${NC}"
    fi

    return $overall_exit
}

# Run main function
main "$@"
