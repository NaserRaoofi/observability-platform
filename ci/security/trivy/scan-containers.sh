#!/bin/bash

set -euo pipefail

# Container Security Scanning with Trivy
echo "🛡️ Running container security scan with Trivy..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/trivy.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if trivy is installed
if ! command -v trivy &> /dev/null; then
    echo -e "${RED}❌ Trivy not found. Installing...${NC}"

    # Install trivy
    case "$(uname -s)" in
        Linux*)
            sudo apt-get update && sudo apt-get install -y wget apt-transport-https gnupg lsb-release
            wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
            echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
            sudo apt-get update && sudo apt-get install -y trivy
            ;;
        Darwin*)
            brew install trivy
            ;;
        *)
            echo -e "${RED}❌ Unsupported OS. Please install trivy manually.${NC}"
            exit 1
            ;;
    esac
fi

# Create reports directory
REPORTS_DIR="$PROJECT_ROOT/.reports/security"
mkdir -p "$REPORTS_DIR"

# Function to scan container images
scan_images() {
    echo -e "${BLUE}📦 Scanning container images...${NC}"

    # Find all image references in Kubernetes manifests and Helm values
    local image_files=$(find "$PROJECT_ROOT/k8s" -name "*.yaml" -o -name "*.yml" | grep -E "(values|deployment)" || true)

    if [ -z "$image_files" ]; then
        echo -e "${YELLOW}⚠️  No Kubernetes manifests found to extract images from${NC}"
        return 0
    fi

    # Extract unique images
    local images=$(grep -h "image:" $image_files | sed 's/.*image:[[:space:]]*//' | sed 's/["\x27]//g' | sort -u | grep -v '{{' || true)

    if [ -z "$images" ]; then
        echo -e "${YELLOW}⚠️  No container images found in manifests${NC}"
        return 0
    fi

    echo -e "${BLUE}Found images to scan:${NC}"
    echo "$images" | sed 's/^/  - /'
    echo ""

    local exit_code=0

    # Scan each image
    while IFS= read -r image; do
        if [ -n "$image" ]; then
            echo -e "${BLUE}🔍 Scanning: $image${NC}"

            local safe_name=$(echo "$image" | tr '/:' '_')
            local report_file="$REPORTS_DIR/trivy-${safe_name}.json"

            if trivy image --config "$CONFIG_FILE" --format json --output "$report_file" "$image"; then
                echo -e "${GREEN}✅ Scan completed for: $image${NC}"
            else
                echo -e "${RED}❌ Scan failed for: $image${NC}"
                exit_code=1
            fi
            echo ""
        fi
    done <<< "$images"

    return $exit_code
}

# Function to scan filesystem
scan_filesystem() {
    echo -e "${BLUE}📁 Scanning filesystem for vulnerabilities...${NC}"

    local report_file="$REPORTS_DIR/trivy-filesystem.json"

    if trivy fs --config "$CONFIG_FILE" --format json --output "$report_file" "$PROJECT_ROOT"; then
        echo -e "${GREEN}✅ Filesystem scan completed${NC}"
        return 0
    else
        echo -e "${RED}❌ Filesystem scan failed${NC}"
        return 1
    fi
}

# Function to generate summary report
generate_summary() {
    echo -e "${BLUE}📊 Generating security summary...${NC}"

    local summary_file="$REPORTS_DIR/security-summary.txt"

    {
        echo "Security Scan Summary"
        echo "===================="
        echo "Scan Date: $(date)"
        echo ""

        # Count vulnerabilities by severity
        local critical=$(find "$REPORTS_DIR" -name "trivy-*.json" -exec jq -r '.Results[]?.Vulnerabilities[]? | select(.Severity=="CRITICAL") | .VulnerabilityID' {} \; 2>/dev/null | wc -l)
        local high=$(find "$REPORTS_DIR" -name "trivy-*.json" -exec jq -r '.Results[]?.Vulnerabilities[]? | select(.Severity=="HIGH") | .VulnerabilityID' {} \; 2>/dev/null | wc -l)
        local medium=$(find "$REPORTS_DIR" -name "trivy-*.json" -exec jq -r '.Results[]?.Vulnerabilities[]? | select(.Severity=="MEDIUM") | .VulnerabilityID' {} \; 2>/dev/null | wc -l)

        echo "Vulnerability Summary:"
        echo "  Critical: $critical"
        echo "  High: $high"
        echo "  Medium: $medium"
        echo ""

        if [ "$critical" -gt 0 ]; then
            echo "❌ CRITICAL vulnerabilities found - immediate action required"
        elif [ "$high" -gt 0 ]; then
            echo "⚠️  HIGH severity vulnerabilities found - should be addressed"
        else
            echo "✅ No critical or high severity vulnerabilities found"
        fi

    } > "$summary_file"

    cat "$summary_file"
}

# Main execution
main() {
    cd "$PROJECT_ROOT"

    echo -e "${BLUE}Starting container security scan...${NC}"
    echo "Project: $PROJECT_ROOT"
    echo "Config: $CONFIG_FILE"
    echo "Reports: $REPORTS_DIR"
    echo ""

    local overall_exit=0

    # Update vulnerability database
    echo -e "${BLUE}🔄 Updating vulnerability database...${NC}"
    trivy image --download-db-only
    echo ""

    # Run scans
    if ! scan_images; then
        overall_exit=1
    fi

    if ! scan_filesystem; then
        overall_exit=1
    fi

    # Generate summary
    generate_summary

    # Final result
    if [ $overall_exit -eq 0 ]; then
        echo -e "${GREEN}✅ Security scan completed successfully${NC}"
    else
        echo -e "${RED}❌ Security scan completed with issues${NC}"
    fi

    return $overall_exit
}

# Run main function
main "$@"
