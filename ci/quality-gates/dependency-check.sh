#!/bin/bash

set -euo pipefail

# Dependency Security Scanning and Vulnerability Assessment
echo "🔍 Running dependency security scan..."

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

    # Check npm audit (for Node.js dependencies)
    if command -v npm &> /dev/null; then
        echo -e "${BLUE}✅ npm found for Node.js dependency scanning${NC}"
    fi

    # Check pip-audit (for Python dependencies)
    if ! command -v pip-audit &> /dev/null; then
        echo -e "${YELLOW}⚠️  pip-audit not found. Installing...${NC}"
        pip3 install pip-audit || true
    fi

    # Check safety (alternative Python scanner)
    if ! command -v safety &> /dev/null; then
        echo -e "${YELLOW}⚠️  safety not found. Installing...${NC}"
        pip3 install safety || true
    fi

    # Check grype (universal vulnerability scanner)
    if ! command -v grype &> /dev/null; then
        echo -e "${YELLOW}⚠️  grype not found. Installing...${NC}"
        case "$(uname -s)" in
            Linux*)
                curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
                ;;
            Darwin*)
                brew install grype
                ;;
        esac
    fi
}

# Function to scan Terraform dependencies
scan_terraform_dependencies() {
    echo -e "${BLUE}🏗️ Scanning Terraform module dependencies...${NC}"

    local terraform_dirs=$(find "$PROJECT_ROOT/terraform" -name "*.tf" -exec dirname {} \; | sort -u)
    local reports_dir="$PROJECT_ROOT/.reports/dependencies"
    mkdir -p "$reports_dir"

    local tf_issues=0

    while IFS= read -r tf_dir; do
        if [ -n "$tf_dir" ] && [ -d "$tf_dir" ]; then
            local rel_path=$(realpath --relative-to="$PROJECT_ROOT" "$tf_dir")
            echo -e "${BLUE}Scanning Terraform directory: $rel_path${NC}"

            cd "$tf_dir"

            # Check for Terraform lock file
            if [ -f ".terraform.lock.hcl" ]; then
                echo -e "${GREEN}✅ Found Terraform lock file${NC}"

                # Extract provider versions
                local lock_report="$reports_dir/terraform-$(echo "$rel_path" | tr '/' '_')-providers.txt"
                {
                    echo "Terraform Providers Report"
                    echo "========================="
                    echo "Directory: $rel_path"
                    echo "Date: $(date)"
                    echo ""

                    # Parse provider versions from lock file
                    awk '/provider/ {provider=$2} /version/ && provider {print provider, $3; provider=""}' .terraform.lock.hcl | head -20

                } > "$lock_report"

                echo -e "${GREEN}✅ Provider inventory saved to: $(basename "$lock_report")${NC}"
            else
                echo -e "${YELLOW}⚠️  No Terraform lock file found in $rel_path${NC}"
            fi

            # Check for outdated providers (if terraform is available)
            if command -v terraform &> /dev/null; then
                echo -e "${BLUE}Checking for provider updates...${NC}"
                if terraform init -upgrade=false &> /dev/null; then
                    if terraform providers lock -platform=linux_amd64 -platform=darwin_amd64 &> /dev/null; then
                        echo -e "${GREEN}✅ Provider versions validated${NC}"
                    else
                        echo -e "${YELLOW}⚠️  Could not validate all providers${NC}"
                    fi
                fi
            fi
        fi
    done <<< "$terraform_dirs"

    return $tf_issues
}

# Function to scan Python dependencies
scan_python_dependencies() {
    echo -e "${BLUE}🐍 Scanning Python dependencies...${NC}"

    local requirements_files=$(find "$PROJECT_ROOT" -name "requirements*.txt" -o -name "Pipfile" -o -name "pyproject.toml")

    if [ -z "$requirements_files" ]; then
        echo -e "${YELLOW}⚠️  No Python dependency files found${NC}"
        return 0
    fi

    local reports_dir="$PROJECT_ROOT/.reports/dependencies"
    local python_issues=0

    while IFS= read -r req_file; do
        if [ -n "$req_file" ]; then
            local rel_path=$(realpath --relative-to="$PROJECT_ROOT" "$req_file")
            echo -e "${BLUE}Scanning: $rel_path${NC}"

            local report_file="$reports_dir/python-$(basename "$req_file" | tr '.' '_').json"

            # Use pip-audit if available
            if command -v pip-audit &> /dev/null; then
                echo -e "${BLUE}Running pip-audit...${NC}"
                if pip-audit --requirement "$req_file" --format=json --output="$report_file" 2>/dev/null; then
                    local vuln_count=$(jq '. | length' "$report_file" 2>/dev/null || echo "0")
                    if [ "$vuln_count" -gt 0 ]; then
                        echo -e "${RED}❌ Found $vuln_count vulnerabilities in $rel_path${NC}"
                        python_issues=1
                    else
                        echo -e "${GREEN}✅ No vulnerabilities found in $rel_path${NC}"
                    fi
                else
                    echo -e "${YELLOW}⚠️  pip-audit scan failed for $rel_path${NC}"
                fi
            fi

            # Use safety as fallback
            if command -v safety &> /dev/null; then
                echo -e "${BLUE}Running safety check...${NC}"
                local safety_report="$reports_dir/safety-$(basename "$req_file" | tr '.' '_').txt"
                if safety check --requirement "$req_file" --output text > "$safety_report" 2>/dev/null; then
                    echo -e "${GREEN}✅ Safety check passed for $rel_path${NC}"
                else
                    echo -e "${YELLOW}⚠️  Safety check found issues in $rel_path${NC}"
                    python_issues=1
                fi
            fi
        fi
    done <<< "$requirements_files"

    return $python_issues
}

# Function to scan Node.js dependencies
scan_nodejs_dependencies() {
    echo -e "${BLUE}📦 Scanning Node.js dependencies...${NC}"

    local package_files=$(find "$PROJECT_ROOT" -name "package.json" | head -10)

    if [ -z "$package_files" ]; then
        echo -e "${YELLOW}⚠️  No package.json files found${NC}"
        return 0
    fi

    local reports_dir="$PROJECT_ROOT/.reports/dependencies"
    local nodejs_issues=0

    while IFS= read -r package_file; do
        if [ -n "$package_file" ]; then
            local package_dir=$(dirname "$package_file")
            local rel_path=$(realpath --relative-to="$PROJECT_ROOT" "$package_dir")

            echo -e "${BLUE}Scanning: $rel_path/package.json${NC}"

            cd "$package_dir"

            # Run npm audit if package-lock.json exists
            if [ -f "package-lock.json" ]; then
                local audit_report="$reports_dir/npm-audit-$(echo "$rel_path" | tr '/' '_').json"

                if npm audit --audit-level=moderate --json > "$audit_report" 2>/dev/null; then
                    local vulnerabilities=$(jq '.metadata.vulnerabilities | to_entries | map(.value) | add' "$audit_report" 2>/dev/null || echo "0")

                    if [ "$vulnerabilities" -gt 0 ]; then
                        echo -e "${RED}❌ Found $vulnerabilities vulnerabilities in $rel_path${NC}"
                        nodejs_issues=1

                        # Show summary
                        echo -e "${YELLOW}Vulnerability summary:${NC}"
                        jq -r '.metadata.vulnerabilities | to_entries[] | "  \(.key): \(.value)"' "$audit_report" 2>/dev/null | head -5 | sed 's/^/  /'
                    else
                        echo -e "${GREEN}✅ No vulnerabilities found in $rel_path${NC}"
                    fi
                else
                    echo -e "${YELLOW}⚠️  npm audit failed for $rel_path${NC}"
                fi
            else
                echo -e "${YELLOW}⚠️  No package-lock.json found in $rel_path${NC}"
            fi
        fi
    done <<< "$package_files"

    return $nodejs_issues
}

# Function to scan container images for vulnerabilities
scan_container_dependencies() {
    echo -e "${BLUE}🐳 Scanning container image dependencies...${NC}"

    # Extract images from Kubernetes manifests
    local image_files=$(find "$PROJECT_ROOT/k8s" -name "*.yaml" -o -name "*.yml" | head -10)

    if [ -z "$image_files" ]; then
        echo -e "${YELLOW}⚠️  No Kubernetes manifests found${NC}"
        return 0
    fi

    # Extract unique images
    local images=$(grep -h "image:" $image_files | sed 's/.*image:[[:space:]]*//' | sed 's/["\x27]//g' | sort -u | grep -v '{{' | head -5 || true)

    if [ -z "$images" ]; then
        echo -e "${YELLOW}⚠️  No container images found${NC}"
        return 0
    fi

    local reports_dir="$PROJECT_ROOT/.reports/dependencies"
    local container_issues=0

    if command -v grype &> /dev/null; then
        echo -e "${BLUE}Using Grype for container scanning...${NC}"

        while IFS= read -r image; do
            if [ -n "$image" ]; then
                echo -e "${BLUE}Scanning image: $image${NC}"

                local safe_name=$(echo "$image" | tr '/:' '_')
                local report_file="$reports_dir/grype-${safe_name}.json"

                if grype "$image" -o json > "$report_file" 2>/dev/null; then
                    local vuln_count=$(jq '.matches | length' "$report_file" 2>/dev/null || echo "0")

                    if [ "$vuln_count" -gt 0 ]; then
                        echo -e "${RED}❌ Found $vuln_count vulnerabilities in $image${NC}"
                        container_issues=1

                        # Show critical/high vulnerabilities
                        local critical=$(jq '.matches[] | select(.vulnerability.severity == "Critical") | .vulnerability.id' "$report_file" 2>/dev/null | wc -l)
                        local high=$(jq '.matches[] | select(.vulnerability.severity == "High") | .vulnerability.id' "$report_file" 2>/dev/null | wc -l)

                        echo -e "${YELLOW}  Critical: $critical, High: $high${NC}"
                    else
                        echo -e "${GREEN}✅ No vulnerabilities found in $image${NC}"
                    fi
                else
                    echo -e "${YELLOW}⚠️  Could not scan $image${NC}"
                fi
            fi
        done <<< "$images"
    else
        echo -e "${YELLOW}⚠️  Grype not available for container scanning${NC}"
    fi

    return $container_issues
}

# Function to check for license compliance
check_license_compliance() {
    echo -e "${BLUE}📜 Checking license compliance...${NC}"

    local reports_dir="$PROJECT_ROOT/.reports/dependencies"
    local license_report="$reports_dir/license-compliance.txt"

    # Problematic licenses that should be flagged
    local problematic_licenses=("GPL" "AGPL" "LGPL-3.0" "GPL-3.0" "SSPL")

    {
        echo "License Compliance Report"
        echo "========================"
        echo "Date: $(date)"
        echo ""

        # Check Python packages
        if command -v pip-licenses &> /dev/null; then
            echo "Python Package Licenses:"
            pip-licenses --format=plain 2>/dev/null | head -20 || echo "  Could not retrieve Python licenses"
        elif [ -f "$PROJECT_ROOT/requirements.txt" ]; then
            echo "Python packages found but pip-licenses not available"
            echo "Consider installing: pip install pip-licenses"
        fi

        echo ""

        # Check Node.js packages
        local package_files=$(find "$PROJECT_ROOT" -name "package.json" | head -5)
        if [ -n "$package_files" ]; then
            echo "Node.js Package Licenses:"
            while IFS= read -r package_file; do
                if [ -n "$package_file" ]; then
                    local package_dir=$(dirname "$package_file")
                    echo "  Package: $(basename "$package_dir")"

                    # Extract license from package.json
                    local license=$(jq -r '.license // "Unknown"' "$package_file" 2>/dev/null)
                    echo "  License: $license"

                    # Check if license is problematic
                    for prob_license in "${problematic_licenses[@]}"; do
                        if [[ "$license" == *"$prob_license"* ]]; then
                            echo "  ⚠️  WARNING: Potentially problematic license detected"
                        fi
                    done
                fi
            done <<< "$package_files"
        fi

        echo ""
        echo "License Compliance Summary:"
        echo "  ✅ Review all licenses for compatibility with your project"
        echo "  ⚠️  Pay special attention to GPL and AGPL licenses"
        echo "  📋 Consider using tools like FOSSA or WhiteSource for enterprise compliance"

    } > "$license_report"

    echo -e "${BLUE}📋 License report saved to: $license_report${NC}"
}

# Function to generate comprehensive dependency report
generate_dependency_report() {
    echo -e "${BLUE}📊 Generating dependency security summary...${NC}"

    local reports_dir="$PROJECT_ROOT/.reports/dependencies"
    local summary_file="$reports_dir/dependency-summary.txt"

    {
        echo "Dependency Security Summary"
        echo "=========================="
        echo "Date: $(date)"
        echo "Project: observability-platform"
        echo ""

        # Count vulnerabilities across all scans
        local total_vulnerabilities=0
        local scanned_components=0

        # Python vulnerabilities
        local python_vulns=$(find "$reports_dir" -name "python-*.json" -exec jq '. | length' {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
        if [ "$python_vulns" -gt 0 ]; then
            echo "🐍 Python Dependencies: $python_vulns vulnerabilities found"
            total_vulnerabilities=$((total_vulnerabilities + python_vulns))
            scanned_components=$((scanned_components + 1))
        fi

        # Node.js vulnerabilities
        local nodejs_vulns=$(find "$reports_dir" -name "npm-audit-*.json" -exec jq '.metadata.vulnerabilities | to_entries | map(.value) | add // 0' {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
        if [ "$nodejs_vulns" -gt 0 ]; then
            echo "📦 Node.js Dependencies: $nodejs_vulns vulnerabilities found"
            total_vulnerabilities=$((total_vulnerabilities + nodejs_vulns))
            scanned_components=$((scanned_components + 1))
        fi

        # Container vulnerabilities
        local container_vulns=$(find "$reports_dir" -name "grype-*.json" -exec jq '.matches | length' {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
        if [ "$container_vulns" -gt 0 ]; then
            echo "🐳 Container Images: $container_vulns vulnerabilities found"
            total_vulnerabilities=$((total_vulnerabilities + container_vulns))
            scanned_components=$((scanned_components + 1))
        fi

        echo ""
        echo "Overall Summary:"
        echo "  📊 Components scanned: $scanned_components"
        echo "  🚨 Total vulnerabilities: $total_vulnerabilities"
        echo ""

        if [ "$total_vulnerabilities" -gt 0 ]; then
            echo "❌ Security vulnerabilities found in dependencies"
            echo ""
            echo "Recommended Actions:"
            echo "  1. Review vulnerability details in component-specific reports"
            echo "  2. Update vulnerable dependencies to patched versions"
            echo "  3. Consider using dependency update tools (Dependabot, Renovate)"
            echo "  4. Implement dependency pinning and regular security updates"
        else
            echo "✅ No security vulnerabilities found in scanned dependencies"
            echo ""
            echo "Best Practices:"
            echo "  ✅ Continue regular dependency scanning"
            echo "  ✅ Keep dependencies updated"
            echo "  ✅ Monitor security advisories for your stack"
        fi

    } > "$summary_file"

    cat "$summary_file"
}

# Main execution
main() {
    cd "$PROJECT_ROOT"

    echo -e "${BLUE}Starting dependency security scanning...${NC}"
    echo "Project: $PROJECT_ROOT"
    echo ""

    check_tools

    local reports_dir="$PROJECT_ROOT/.reports/dependencies"
    mkdir -p "$reports_dir"

    local overall_exit=0

    # Run dependency scans
    if ! scan_terraform_dependencies; then
        overall_exit=1
    fi
    echo ""

    if ! scan_python_dependencies; then
        overall_exit=1
    fi
    echo ""

    if ! scan_nodejs_dependencies; then
        overall_exit=1
    fi
    echo ""

    if ! scan_container_dependencies; then
        overall_exit=1
    fi
    echo ""

    # Check license compliance
    check_license_compliance
    echo ""

    # Generate comprehensive report
    generate_dependency_report

    # Final result
    if [ $overall_exit -eq 0 ]; then
        echo -e "${GREEN}✅ Dependency security scan completed successfully${NC}"
    else
        echo -e "${RED}❌ Dependency security scan found issues${NC}"
    fi

    return $overall_exit
}

# Run main function
main "$@"
