#!/bin/bash

set -euo pipefail

# Kubernetes Manifests Validation with Kustomize
echo "☸️ Running Kubernetes manifests validation..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to check required tools
check_tools() {
    local missing_tools=()

    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi

    # Check kustomize (or use kubectl kustomize)
    if ! command -v kustomize &> /dev/null; then
        if ! kubectl kustomize --help &> /dev/null; then
            missing_tools+=("kustomize")
        fi
    fi

    # Check yq for YAML processing
    if ! command -v yq &> /dev/null; then
        echo -e "${YELLOW}⚠️  yq not found. Installing...${NC}"
        case "$(uname -s)" in
            Linux*)
                wget -qO /tmp/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
                chmod +x /tmp/yq && sudo mv /tmp/yq /usr/local/bin/yq
                ;;
            Darwin*)
                brew install yq
                ;;
        esac
    fi

    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo -e "${RED}❌ Missing required tools: ${missing_tools[*]}${NC}"
        echo "Please install the missing tools and try again."
        exit 1
    fi

    echo -e "${BLUE}Using kubectl version: $(kubectl version --client --short 2>/dev/null || echo 'Unknown')${NC}"
}

# Function to validate kustomize builds
validate_kustomize_builds() {
    echo -e "${BLUE}🔧 Validating Kustomize builds...${NC}"

    # Find all kustomization.yaml files
    local kustomize_dirs=$(find "$PROJECT_ROOT/k8s" -name "kustomization.yaml" -exec dirname {} \;)

    if [ -z "$kustomize_dirs" ]; then
        echo -e "${YELLOW}⚠️  No kustomization.yaml files found${NC}"
        return 0
    fi

    local build_issues=0
    local reports_dir="$PROJECT_ROOT/.reports/validation"
    mkdir -p "$reports_dir"

    while IFS= read -r kustomize_dir; do
        if [ -n "$kustomize_dir" ]; then
            local rel_path=$(realpath --relative-to="$PROJECT_ROOT" "$kustomize_dir")
            echo -e "${BLUE}Building: $rel_path${NC}"

            local output_file="$reports_dir/kustomize-$(echo "$rel_path" | tr '/' '_').yaml"

            cd "$kustomize_dir"

            # Try kustomize build
            if command -v kustomize &> /dev/null; then
                local build_cmd="kustomize build ."
            else
                local build_cmd="kubectl kustomize ."
            fi

            if $build_cmd > "$output_file" 2>/dev/null; then
                echo -e "${GREEN}✅ Build successful: $rel_path${NC}"

                # Validate the generated YAML
                if ! yq eval '.' "$output_file" > /dev/null 2>&1; then
                    echo -e "${RED}❌ Generated YAML is invalid: $rel_path${NC}"
                    build_issues=1
                fi
            else
                echo -e "${RED}❌ Build failed: $rel_path${NC}"
                build_issues=1

                # Show build error
                echo -e "${YELLOW}Error details:${NC}"
                $build_cmd 2>&1 | head -10 | sed 's/^/  /'
            fi
        fi
    done <<< "$kustomize_dirs"

    return $build_issues
}

# Function to validate individual YAML files
validate_yaml_syntax() {
    echo -e "${BLUE}📝 Validating YAML syntax...${NC}"

    local yaml_files=$(find "$PROJECT_ROOT/k8s" -name "*.yaml" -o -name "*.yml")

    if [ -z "$yaml_files" ]; then
        echo -e "${YELLOW}⚠️  No YAML files found${NC}"
        return 0
    fi

    local syntax_issues=0
    local checked_count=0

    while IFS= read -r yaml_file; do
        if [ -n "$yaml_file" ]; then
            local rel_path=$(realpath --relative-to="$PROJECT_ROOT" "$yaml_file")

            # Skip generated files
            if [[ "$rel_path" =~ \.reports/ ]]; then
                continue
            fi

            checked_count=$((checked_count + 1))

            if yq eval '.' "$yaml_file" > /dev/null 2>&1; then
                echo -e "${GREEN}✅ Valid: $rel_path${NC}"
            else
                echo -e "${RED}❌ Invalid YAML: $rel_path${NC}"
                syntax_issues=1

                # Show syntax error
                echo -e "${YELLOW}Error:${NC}"
                yq eval '.' "$yaml_file" 2>&1 | head -3 | sed 's/^/  /'
            fi
        fi
    done <<< "$yaml_files"

    echo -e "${BLUE}Checked $checked_count YAML files${NC}"
    return $syntax_issues
}

# Function to validate Kubernetes resource definitions
validate_k8s_resources() {
    echo -e "${BLUE}🔍 Validating Kubernetes resource definitions...${NC}"

    local reports_dir="$PROJECT_ROOT/.reports/validation"
    local built_manifests=$(find "$reports_dir" -name "kustomize-*.yaml")

    if [ -z "$built_manifests" ]; then
        echo -e "${YELLOW}⚠️  No built manifests found to validate${NC}"
        return 0
    fi

    local validation_issues=0

    while IFS= read -r manifest_file; do
        if [ -n "$manifest_file" ]; then
            local manifest_name=$(basename "$manifest_file" .yaml)
            echo -e "${BLUE}Validating resources in: $manifest_name${NC}"

            # Use kubectl to validate (dry-run)
            if kubectl apply --dry-run=client --validate=true -f "$manifest_file" > /dev/null 2>&1; then
                echo -e "${GREEN}✅ Resource validation passed: $manifest_name${NC}"
            else
                echo -e "${RED}❌ Resource validation failed: $manifest_name${NC}"
                validation_issues=1

                # Show validation errors
                echo -e "${YELLOW}Validation errors:${NC}"
                kubectl apply --dry-run=client --validate=true -f "$manifest_file" 2>&1 | head -5 | sed 's/^/  /'
            fi
        fi
    done <<< "$built_manifests"

    return $validation_issues
}

# Function to check for common Kubernetes best practices
validate_best_practices() {
    echo -e "${BLUE}📋 Checking Kubernetes best practices...${NC}"

    local reports_dir="$PROJECT_ROOT/.reports/validation"
    local built_manifests=$(find "$reports_dir" -name "kustomize-*.yaml")

    if [ -z "$built_manifests" ]; then
        echo -e "${YELLOW}⚠️  No built manifests found for best practices check${NC}"
        return 0
    fi

    local practice_issues=0
    local report_file="$reports_dir/k8s-best-practices.txt"

    {
        echo "Kubernetes Best Practices Report"
        echo "==============================="
        echo "Date: $(date)"
        echo ""
    } > "$report_file"

    while IFS= read -r manifest_file; do
        if [ -n "$manifest_file" ]; then
            local manifest_name=$(basename "$manifest_file" .yaml)

            echo -e "${BLUE}Checking best practices for: $manifest_name${NC}"

            {
                echo "Manifest: $manifest_name"
                echo "------------------------"
            } >> "$report_file"

            # Check for resource limits
            local deployments_without_limits=$(yq eval '.spec.template.spec.containers[] | select(.resources.limits == null) | .name' "$manifest_file" 2>/dev/null | wc -l)
            if [ "$deployments_without_limits" -gt 0 ]; then
                echo -e "${YELLOW}⚠️  Found $deployments_without_limits containers without resource limits${NC}"
                echo "  ⚠️  Containers without resource limits: $deployments_without_limits" >> "$report_file"
                practice_issues=1
            fi

            # Check for security contexts
            local pods_without_security_context=$(yq eval 'select(.kind == "Deployment") | .spec.template.spec | select(.securityContext == null) | "missing"' "$manifest_file" 2>/dev/null | wc -l)
            if [ "$pods_without_security_context" -gt 0 ]; then
                echo -e "${YELLOW}⚠️  Found pods without security context${NC}"
                echo "  ⚠️  Pods without security context: $pods_without_security_context" >> "$report_file"
                practice_issues=1
            fi

            # Check for health checks
            local containers_without_probes=$(yq eval '.spec.template.spec.containers[] | select(.readinessProbe == null or .livenessProbe == null) | .name' "$manifest_file" 2>/dev/null | wc -l)
            if [ "$containers_without_probes" -gt 0 ]; then
                echo -e "${YELLOW}⚠️  Found $containers_without_probes containers without health checks${NC}"
                echo "  ⚠️  Containers without health checks: $containers_without_probes" >> "$report_file"
                practice_issues=1
            fi

            echo "" >> "$report_file"
        fi
    done <<< "$built_manifests"

    {
        echo "Summary:"
        echo "--------"
        if [ $practice_issues -eq 0 ]; then
            echo "✅ All best practices checks passed"
        else
            echo "⚠️  Some best practices violations found"
        fi
    } >> "$report_file"

    echo -e "${BLUE}📊 Best practices report saved to: $report_file${NC}"

    return $practice_issues
}

# Generate validation report
generate_report() {
    local reports_dir="$PROJECT_ROOT/.reports/validation"
    local report_file="$reports_dir/k8s-validation.txt"

    {
        echo "Kubernetes Validation Report"
        echo "============================"
        echo "Date: $(date)"
        echo "Project: observability-platform"
        echo ""
        echo "Validation Summary:"
        echo "  ✅ Kustomize builds: $1"
        echo "  ✅ YAML syntax: $2"
        echo "  ✅ Resource validation: $3"
        echo "  ✅ Best practices: $4"
        echo ""

        if [ "$1" = "PASSED" ] && [ "$2" = "PASSED" ] && [ "$3" = "PASSED" ] && [ "$4" = "PASSED" ]; then
            echo "✅ All Kubernetes validations passed"
        else
            echo "❌ Some Kubernetes validations failed"
        fi
    } > "$report_file"

    echo -e "${BLUE}📊 Validation report saved to: $report_file${NC}"
}

# Main execution
main() {
    cd "$PROJECT_ROOT"

    echo -e "${BLUE}Starting Kubernetes validation...${NC}"
    echo "Project: $PROJECT_ROOT"
    echo ""

    check_tools

    local overall_exit=0
    local build_result="PASSED"
    local syntax_result="PASSED"
    local resource_result="PASSED"
    local practices_result="PASSED"

    # Run validations
    if ! validate_yaml_syntax; then
        overall_exit=1
        syntax_result="FAILED"
    fi
    echo ""

    if ! validate_kustomize_builds; then
        overall_exit=1
        build_result="FAILED"
    fi
    echo ""

    if ! validate_k8s_resources; then
        overall_exit=1
        resource_result="FAILED"
    fi
    echo ""

    if ! validate_best_practices; then
        overall_exit=1
        practices_result="FAILED"
    fi
    echo ""

    # Generate report
    generate_report "$build_result" "$syntax_result" "$resource_result" "$practices_result"

    # Final result
    if [ $overall_exit -eq 0 ]; then
        echo -e "${GREEN}✅ All Kubernetes validations passed${NC}"
    else
        echo -e "${RED}❌ Some Kubernetes validations failed${NC}"
    fi

    return $overall_exit
}

# Run main function
main "$@"
