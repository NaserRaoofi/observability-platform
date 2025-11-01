#!/bin/bash

set -euo pipefail

# Infrastructure Security Scanning with Checkov
echo "🔒 Running infrastructure security scan with Checkov..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/.checkov.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if checkov is installed
if ! command -v checkov &> /dev/null; then
    echo -e "${RED}❌ Checkov not found. Installing...${NC}"
    pip3 install checkov || {
        echo -e "${RED}❌ Failed to install checkov. Please install manually.${NC}"
        exit 1
    }
fi

# Create reports directory
REPORTS_DIR="$PROJECT_ROOT/.reports/security"
mkdir -p "$REPORTS_DIR"

# Function to scan Terraform
scan_terraform() {
    echo -e "${BLUE}🏗️ Scanning Terraform infrastructure...${NC}"

    local terraform_dir="$PROJECT_ROOT/terraform"
    if [ ! -d "$terraform_dir" ]; then
        echo -e "${YELLOW}⚠️  Terraform directory not found: $terraform_dir${NC}"
        return 0
    fi

    local report_file="$REPORTS_DIR/checkov-terraform.json"

    echo -e "${BLUE}Scanning directory: $terraform_dir${NC}"

    if checkov \
        --config-file "$CONFIG_FILE" \
        --directory "$terraform_dir" \
        --framework terraform \
        --output json \
        --output-file "$report_file" \
        --quiet; then
        echo -e "${GREEN}✅ Terraform scan completed${NC}"
        return 0
    else
        echo -e "${RED}❌ Terraform scan found issues${NC}"
        return 1
    fi
}

# Function to scan Kubernetes manifests
scan_kubernetes() {
    echo -e "${BLUE}☸️ Scanning Kubernetes manifests...${NC}"

    local k8s_dir="$PROJECT_ROOT/k8s"
    if [ ! -d "$k8s_dir" ]; then
        echo -e "${YELLOW}⚠️  Kubernetes directory not found: $k8s_dir${NC}"
        return 0
    fi

    local report_file="$REPORTS_DIR/checkov-kubernetes.json"

    echo -e "${BLUE}Scanning directory: $k8s_dir${NC}"

    if checkov \
        --config-file "$CONFIG_FILE" \
        --directory "$k8s_dir" \
        --framework kubernetes \
        --output json \
        --output-file "$report_file" \
        --quiet; then
        echo -e "${GREEN}✅ Kubernetes scan completed${NC}"
        return 0
    else
        echo -e "${RED}❌ Kubernetes scan found issues${NC}"
        return 1
    fi
}

# Function to scan for secrets
scan_secrets() {
    echo -e "${BLUE}🔐 Scanning for exposed secrets...${NC}"

    local report_file="$REPORTS_DIR/checkov-secrets.json"

    # Exclude certain directories/files
    local exclude_paths=(
        ".git"
        ".reports"
        "node_modules"
        "*.md"
        "*.txt"
        "LICENSE"
    )

    local exclude_args=""
    for path in "${exclude_paths[@]}"; do
        exclude_args+=" --skip-path $path"
    done

    if checkov \
        --directory "$PROJECT_ROOT" \
        --framework secrets \
        $exclude_args \
        --output json \
        --output-file "$report_file" \
        --quiet; then
        echo -e "${GREEN}✅ Secrets scan completed${NC}"
        return 0
    else
        echo -e "${RED}❌ Secrets scan found issues${NC}"
        return 1
    fi
}

# Function to scan Dockerfiles
scan_dockerfiles() {
    echo -e "${BLUE}🐳 Scanning Dockerfiles...${NC}"

    # Find Dockerfiles
    local dockerfiles=$(find "$PROJECT_ROOT" -name "Dockerfile*" -o -name "*.dockerfile" | head -10)

    if [ -z "$dockerfiles" ]; then
        echo -e "${YELLOW}⚠️  No Dockerfiles found${NC}"
        return 0
    fi

    local report_file="$REPORTS_DIR/checkov-dockerfile.json"

    echo -e "${BLUE}Found Dockerfiles:${NC}"
    echo "$dockerfiles" | sed 's/^/  - /'
    echo ""

    if checkov \
        --framework dockerfile \
        $(echo "$dockerfiles" | sed 's/^/--file /' | tr '\n' ' ') \
        --output json \
        --output-file "$report_file" \
        --quiet; then
        echo -e "${GREEN}✅ Dockerfile scan completed${NC}"
        return 0
    else
        echo -e "${RED}❌ Dockerfile scan found issues${NC}"
        return 1
    fi
}

# Function to generate summary report
generate_summary() {
    echo -e "${BLUE}📊 Generating security summary...${NC}"

    local summary_file="$REPORTS_DIR/checkov-summary.txt"

    {
        echo "Infrastructure Security Scan Summary"
        echo "===================================="
        echo "Scan Date: $(date)"
        echo ""

        # Parse results from JSON files
        local total_failed=0
        local total_passed=0
        local total_skipped=0

        for json_file in "$REPORTS_DIR"/checkov-*.json; do
            if [ -f "$json_file" ]; then
                local failed=$(jq -r '.summary.failed // 0' "$json_file" 2>/dev/null || echo "0")
                local passed=$(jq -r '.summary.passed // 0' "$json_file" 2>/dev/null || echo "0")
                local skipped=$(jq -r '.summary.skipped // 0' "$json_file" 2>/dev/null || echo "0")

                total_failed=$((total_failed + failed))
                total_passed=$((total_passed + passed))
                total_skipped=$((total_skipped + skipped))

                local scan_type=$(basename "$json_file" .json | sed 's/checkov-//')
                echo "$scan_type: Failed=$failed, Passed=$passed, Skipped=$skipped"
            fi
        done

        echo ""
        echo "Overall Summary:"
        echo "  ❌ Failed: $total_failed"
        echo "  ✅ Passed: $total_passed"
        echo "  ⏭️  Skipped: $total_skipped"
        echo ""

        if [ "$total_failed" -gt 0 ]; then
            echo "❌ Security issues found - review and fix before deployment"
        else
            echo "✅ All security checks passed"
        fi

    } > "$summary_file"

    cat "$summary_file"
}

# Main execution
main() {
    cd "$PROJECT_ROOT"

    echo -e "${BLUE}Starting infrastructure security scan...${NC}"
    echo "Project: $PROJECT_ROOT"
    echo "Config: $CONFIG_FILE"
    echo "Reports: $REPORTS_DIR"
    echo ""

    local overall_exit=0

    # Run scans
    if ! scan_terraform; then
        overall_exit=1
    fi
    echo ""

    if ! scan_kubernetes; then
        overall_exit=1
    fi
    echo ""

    if ! scan_secrets; then
        overall_exit=1
    fi
    echo ""

    if ! scan_dockerfiles; then
        overall_exit=1
    fi
    echo ""

    # Generate summary
    generate_summary

    # Final result
    if [ $overall_exit -eq 0 ]; then
        echo -e "${GREEN}✅ Infrastructure security scan completed successfully${NC}"
    else
        echo -e "${RED}❌ Infrastructure security scan completed with issues${NC}"
    fi

    return $overall_exit
}

# Run main function
main "$@"
