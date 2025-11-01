#!/bin/bash

set -euo pipefail

# OPA Policy Testing with Conftest
echo "📜 Running OPA policy tests with Conftest..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to check conftest installation
check_conftest() {
    if ! command -v conftest &> /dev/null; then
        echo -e "${RED}❌ Conftest not found. Installing...${NC}"

        # Install conftest
        case "$(uname -s)" in
            Linux*)
                wget -q https://github.com/open-policy-agent/conftest/releases/download/v0.46.0/conftest_0.46.0_Linux_x86_64.tar.gz
                tar xzf conftest_0.46.0_Linux_x86_64.tar.gz
                sudo mv conftest /usr/local/bin
                rm conftest_0.46.0_Linux_x86_64.tar.gz
                ;;
            Darwin*)
                brew install conftest
                ;;
            *)
                echo -e "${RED}❌ Unsupported OS. Please install conftest manually.${NC}"
                exit 1
                ;;
        esac
    fi

    local conftest_version=$(conftest --version)
    echo -e "${BLUE}Using Conftest: $conftest_version${NC}"
}

# Function to validate policy syntax
validate_policies() {
    echo -e "${BLUE}🔍 Validating OPA policy syntax...${NC}"

    local policy_files=$(find "$SCRIPT_DIR" -name "*.rego")
    local validation_issues=0

    while IFS= read -r policy_file; do
        if [ -n "$policy_file" ]; then
            local policy_name=$(basename "$policy_file")
            echo -e "${BLUE}Validating policy: $policy_name${NC}"

            if opa fmt --diff "$policy_file"; then
                echo -e "${GREEN}✅ Policy syntax valid: $policy_name${NC}"
            else
                echo -e "${RED}❌ Policy syntax invalid: $policy_name${NC}"
                validation_issues=1
            fi
        fi
    done <<< "$policy_files"

    return $validation_issues
}

# Function to test policies against Kubernetes manifests
test_kubernetes_policies() {
    echo -e "${BLUE}☸️ Testing policies against Kubernetes manifests...${NC}"

    local k8s_files=$(find "$PROJECT_ROOT/k8s" -name "*.yaml" -o -name "*.yml" | grep -v ".reports" | head -20)

    if [ -z "$k8s_files" ]; then
        echo -e "${YELLOW}⚠️  No Kubernetes manifests found${NC}"
        return 0
    fi

    local reports_dir="$PROJECT_ROOT/.reports/policy"
    mkdir -p "$reports_dir"

    local test_issues=0
    local total_files=0
    local passed_files=0
    local failed_files=0

    echo -e "${BLUE}Testing policies against manifests...${NC}"

    while IFS= read -r manifest_file; do
        if [ -n "$manifest_file" ]; then
            total_files=$((total_files + 1))
            local rel_path=$(realpath --relative-to="$PROJECT_ROOT" "$manifest_file")

            echo -e "${BLUE}Testing: $rel_path${NC}"

            local test_output_file="$reports_dir/conftest-$(echo "$rel_path" | tr '/' '_').txt"

            if conftest test --policy "$SCRIPT_DIR" "$manifest_file" > "$test_output_file" 2>&1; then
                echo -e "${GREEN}✅ Policies passed: $rel_path${NC}"
                passed_files=$((passed_files + 1))
            else
                echo -e "${RED}❌ Policy violations found: $rel_path${NC}"
                failed_files=$((failed_files + 1))
                test_issues=1

                # Show first few violations
                echo -e "${YELLOW}Violations:${NC}"
                head -5 "$test_output_file" | sed 's/^/  /'
            fi
        fi
    done <<< "$k8s_files"

    echo ""
    echo -e "${BLUE}Policy Test Summary:${NC}"
    echo -e "  📊 Total files tested: $total_files"
    echo -e "  ✅ Files passed: $passed_files"
    echo -e "  ❌ Files failed: $failed_files"

    return $test_issues
}

# Function to test policies against built Kustomize manifests
test_kustomize_policies() {
    echo -e "${BLUE}🔧 Testing policies against Kustomize builds...${NC}"

    local reports_dir="$PROJECT_ROOT/.reports/validation"
    local built_manifests=$(find "$reports_dir" -name "kustomize-*.yaml" 2>/dev/null || true)

    if [ -z "$built_manifests" ]; then
        echo -e "${YELLOW}⚠️  No Kustomize builds found. Run validation first.${NC}"
        return 0
    fi

    local policy_reports_dir="$PROJECT_ROOT/.reports/policy"
    mkdir -p "$policy_reports_dir"

    local kustomize_issues=0

    while IFS= read -r manifest_file; do
        if [ -n "$manifest_file" ]; then
            local manifest_name=$(basename "$manifest_file" .yaml)
            echo -e "${BLUE}Testing Kustomize build: $manifest_name${NC}"

            local test_output_file="$policy_reports_dir/conftest-$manifest_name.txt"

            if conftest test --policy "$SCRIPT_DIR" "$manifest_file" > "$test_output_file" 2>&1; then
                echo -e "${GREEN}✅ Kustomize build passed policies: $manifest_name${NC}"
            else
                echo -e "${RED}❌ Kustomize build failed policies: $manifest_name${NC}"
                kustomize_issues=1

                # Show violations
                echo -e "${YELLOW}Policy violations:${NC}"
                head -10 "$test_output_file" | sed 's/^/  /'
            fi
        fi
    done <<< "$built_manifests"

    return $kustomize_issues
}

# Function to run unit tests for policies
test_policy_units() {
    echo -e "${BLUE}🧪 Running policy unit tests...${NC}"

    # Check if policy test files exist
    local test_files=$(find "$SCRIPT_DIR" -name "*_test.rego" 2>/dev/null || true)

    if [ -z "$test_files" ]; then
        echo -e "${YELLOW}⚠️  No policy unit tests found${NC}"
        echo -e "${YELLOW}Consider adding *_test.rego files for policy testing${NC}"
        return 0
    fi

    local test_issues=0

    while IFS= read -r test_file; do
        if [ -n "$test_file" ]; then
            local test_name=$(basename "$test_file")
            echo -e "${BLUE}Running unit tests: $test_name${NC}"

            if opa test "$SCRIPT_DIR"; then
                echo -e "${GREEN}✅ Unit tests passed: $test_name${NC}"
            else
                echo -e "${RED}❌ Unit tests failed: $test_name${NC}"
                test_issues=1
            fi
        fi
    done <<< "$test_files"

    return $test_issues
}

# Function to generate comprehensive policy report
generate_policy_report() {
    echo -e "${BLUE}📊 Generating policy test report...${NC}"

    local reports_dir="$PROJECT_ROOT/.reports/policy"
    local summary_file="$reports_dir/policy-summary.txt"

    {
        echo "OPA Policy Test Summary"
        echo "======================"
        echo "Date: $(date)"
        echo "Project: observability-platform"
        echo ""

        # Count violations across all test files
        local total_violations=0
        local total_tests=0

        for test_file in "$reports_dir"/conftest-*.txt; do
            if [ -f "$test_file" ]; then
                local violations=$(grep -c "FAIL" "$test_file" 2>/dev/null || echo "0")
                local tests=$(grep -c "^FAIL\|^WARN" "$test_file" 2>/dev/null || echo "0")

                total_violations=$((total_violations + violations))
                total_tests=$((total_tests + tests))

                local test_name=$(basename "$test_file" .txt)
                echo "$test_name: $violations violations"
            fi
        done

        echo ""
        echo "Overall Summary:"
        echo "  Total policy tests: $total_tests"
        echo "  Total violations: $total_violations"
        echo ""

        if [ "$total_violations" -gt 0 ]; then
            echo "❌ Policy violations found - review and fix before deployment"
        else
            echo "✅ All policy tests passed"
        fi

        echo ""
        echo "Policy Categories Tested:"
        echo "  🔒 Security policies"
        echo "  🌐 Network policies"
        echo "  📋 Governance policies"
        echo ""

        echo "Next Steps:"
        if [ "$total_violations" -gt 0 ]; then
            echo "  1. Review violation details in individual test files"
            echo "  2. Fix policy violations in manifests"
            echo "  3. Re-run policy tests to verify fixes"
        else
            echo "  ✅ Ready for deployment - all policies satisfied"
        fi

    } > "$summary_file"

    cat "$summary_file"
    echo -e "${BLUE}📋 Detailed policy report saved to: $summary_file${NC}"
}

# Main execution
main() {
    cd "$PROJECT_ROOT"

    echo -e "${BLUE}Starting OPA policy testing...${NC}"
    echo "Project: $PROJECT_ROOT"
    echo "Policies: $SCRIPT_DIR"
    echo ""

    check_conftest

    local overall_exit=0

    # Run policy validation
    if ! validate_policies; then
        overall_exit=1
    fi
    echo ""

    # Run policy unit tests
    if ! test_policy_units; then
        overall_exit=1
    fi
    echo ""

    # Test against Kubernetes manifests
    if ! test_kubernetes_policies; then
        overall_exit=1
    fi
    echo ""

    # Test against Kustomize builds
    if ! test_kustomize_policies; then
        overall_exit=1
    fi
    echo ""

    # Generate comprehensive report
    generate_policy_report

    # Final result
    if [ $overall_exit -eq 0 ]; then
        echo -e "${GREEN}✅ All policy tests passed${NC}"
    else
        echo -e "${RED}❌ Some policy tests failed${NC}"
    fi

    return $overall_exit
}

# Run main function
main "$@"
