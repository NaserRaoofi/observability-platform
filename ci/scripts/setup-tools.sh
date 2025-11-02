#!/bin/bash

set -euo pipefail

# CI Environment Setup Script
echo "🛠️ Setting up CI environment..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to detect OS
detect_os() {
    case "$(uname -s)" in
        Linux*)     OS="linux" ;;
        Darwin*)    OS="darwin" ;;
        *)          OS="unknown" ;;
    esac

    echo -e "${BLUE}Detected OS: $OS${NC}"
}

# Function to install system dependencies
install_system_dependencies() {
    echo -e "${BLUE}📦 Installing system dependencies...${NC}"

    case "$OS" in
        linux)
            # Update package list
            if command -v apt-get &> /dev/null; then
                sudo apt-get update -qq

                # Install required packages
                sudo apt-get install -y \
                    curl \
                    wget \
                    jq \
                    git \
                    unzip \
                    ca-certificates \
                    gnupg \
                    lsb-release \
                    python3 \
                    python3-pip \
                    nodejs \
                    npm

                echo -e "${GREEN}✅ System dependencies installed (Ubuntu/Debian)${NC}"

            elif command -v yum &> /dev/null; then
                sudo yum update -y
                sudo yum install -y curl wget jq git unzip python3 python3-pip nodejs npm
                echo -e "${GREEN}✅ System dependencies installed (RHEL/CentOS)${NC}"

            else
                echo -e "${YELLOW}⚠️  Unknown Linux distribution. Please install dependencies manually.${NC}"
            fi
            ;;

        darwin)
            # Check if Homebrew is installed
            if ! command -v brew &> /dev/null; then
                echo -e "${YELLOW}⚠️  Homebrew not found. Installing...${NC}"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi

            # Install dependencies via Homebrew
            brew update
            brew install curl wget jq git python3 node
            echo -e "${GREEN}✅ System dependencies installed (macOS)${NC}"
            ;;

        *)
            echo -e "${RED}❌ Unsupported operating system${NC}"
            exit 1
            ;;
    esac
}

# Function to install CI tools
install_ci_tools() {
    echo -e "${BLUE}🔧 Installing CI tools...${NC}"

    # Create tools directory
    local tools_dir="$HOME/.local/bin"
    mkdir -p "$tools_dir"

    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$tools_dir:"* ]]; then
        echo "export PATH=\"$tools_dir:\$PATH\"" >> ~/.bashrc
        echo "export PATH=\"$tools_dir:\$PATH\"" >> ~/.zshrc 2>/dev/null || true
        export PATH="$tools_dir:$PATH"
    fi

    # Install kubectl
    if ! command -v kubectl &> /dev/null; then
        echo -e "${BLUE}Installing kubectl...${NC}"
        case "$OS" in
            linux)
                curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                chmod +x kubectl && mv kubectl "$tools_dir/"
                ;;
            darwin)
                curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
                chmod +x kubectl && mv kubectl "$tools_dir/"
                ;;
        esac
        echo -e "${GREEN}✅ kubectl installed${NC}"
    fi

    # Install kustomize
    if ! command -v kustomize &> /dev/null; then
        echo -e "${BLUE}Installing kustomize...${NC}"
        case "$OS" in
            linux)
                curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
                mv kustomize "$tools_dir/"
                ;;
            darwin)
                brew install kustomize
                ;;
        esac
        echo -e "${GREEN}✅ kustomize installed${NC}"
    fi

    # Install helm
    if ! command -v helm &> /dev/null; then
        echo -e "${BLUE}Installing helm...${NC}"
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
        echo -e "${GREEN}✅ helm installed${NC}"
    fi

    # Install terraform
    if ! command -v terraform &> /dev/null; then
        echo -e "${BLUE}Installing terraform...${NC}"
        case "$OS" in
            linux)
                wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
                echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
                sudo apt-get update && sudo apt-get install -y terraform
                ;;
            darwin)
                brew install terraform
                ;;
        esac
        echo -e "${GREEN}✅ terraform installed${NC}"
    fi

    # Install tfsec
    if ! command -v tfsec &> /dev/null; then
        echo -e "${BLUE}Installing tfsec...${NC}"
        case "$OS" in
            linux)
                curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash
                mv tfsec "$tools_dir/"
                ;;
            darwin)
                brew install tfsec
                ;;
        esac
        echo -e "${GREEN}✅ tfsec installed${NC}"
    fi

    # Install trivy
    if ! command -v trivy &> /dev/null; then
        echo -e "${BLUE}Installing trivy...${NC}"
        case "$OS" in
            linux)
                sudo sh -c 'echo "deb http://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" > /etc/apt/sources.list.d/trivy.list'
                wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
                sudo apt-get update && sudo apt-get install -y trivy
                ;;
            darwin)
                brew install trivy
                ;;
        esac
        echo -e "${GREEN}✅ trivy installed${NC}"
    fi

    # Install conftest
    if ! command -v conftest &> /dev/null; then
        echo -e "${BLUE}Installing conftest...${NC}"
        case "$OS" in
            linux)
                wget https://github.com/open-policy-agent/conftest/releases/download/v0.46.0/conftest_0.46.0_Linux_x86_64.tar.gz
                tar xzf conftest_0.46.0_Linux_x86_64.tar.gz
                mv conftest "$tools_dir/"
                rm conftest_0.46.0_Linux_x86_64.tar.gz
                ;;
            darwin)
                brew install conftest
                ;;
        esac
        echo -e "${GREEN}✅ conftest installed${NC}"
    fi

    # Install yq
    if ! command -v yq &> /dev/null; then
        echo -e "${BLUE}Installing yq...${NC}"
        case "$OS" in
            linux)
                wget -qO "$tools_dir/yq" https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
                chmod +x "$tools_dir/yq"
                ;;
            darwin)
                brew install yq
                ;;
        esac
        echo -e "${GREEN}✅ yq installed${NC}"
    fi
}

# Function to install Python tools
install_python_tools() {
    echo -e "${BLUE}🐍 Installing Python CI tools...${NC}"

    # Upgrade pip
    python3 -m pip install --upgrade pip

    # Install Python tools
    python3 -m pip install --user \
        checkov \
        safety \
        pip-audit \
        yamllint \
        bandit \
        pre-commit

    echo -e "${GREEN}✅ Python CI tools installed${NC}"
}

# Function to install Node.js tools
install_nodejs_tools() {
    echo -e "${BLUE}📦 Installing Node.js CI tools...${NC}"

    # Install global npm packages
    npm install -g \
        markdownlint-cli \
        jsonlint \
        @commitlint/cli \
        @commitlint/config-conventional

    echo -e "${GREEN}✅ Node.js CI tools installed${NC}"
}

# Function to setup Git hooks
setup_git_hooks() {
    echo -e "${BLUE}🪝 Setting up Git hooks...${NC}"

    cd "$PROJECT_ROOT"

    # Install pre-commit if not already done
    if command -v pre-commit &> /dev/null; then
        # Initialize pre-commit (will be configured later)
        if [ -f ".pre-commit-config.yaml" ]; then
            pre-commit install
            echo -e "${GREEN}✅ Pre-commit hooks installed${NC}"
        else
            echo -e "${YELLOW}⚠️  .pre-commit-config.yaml not found${NC}"
        fi
    fi
}

# Function to create necessary directories
create_directories() {
    echo -e "${BLUE}📁 Creating necessary directories...${NC}"

    cd "$PROJECT_ROOT"

    local directories=(
        ".reports"
        ".reports/security"
        ".reports/validation"
        ".reports/policy"
        ".reports/dependencies"
        ".cache"
        "tmp"
    )

    for dir in "${directories[@]}"; do
        mkdir -p "$dir"
        echo -e "${GREEN}✅ Created: $dir${NC}"
    done

    # Add .gitignore entries
    if [ -f ".gitignore" ]; then
        {
            echo ""
            echo "# CI/CD generated files"
            echo ".reports/"
            echo ".cache/"
            echo "tmp/"
            echo "terraform.plan"
            echo "*.tfstate*"
        } >> .gitignore
        echo -e "${GREEN}✅ Updated .gitignore${NC}"
    fi
}

# Function to verify installation
verify_installation() {
    echo -e "${BLUE}🔍 Verifying CI tool installation...${NC}"

    local tools=(
        "kubectl"
        "kustomize"
        "helm"
        "terraform"
        "tfsec"
        "trivy"
        "conftest"
        "yq"
        "checkov"
        "yamllint"
        "markdownlint"
    )

    local missing_tools=()
    local installed_count=0

    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            local version=$(${tool} version 2>/dev/null || ${tool} --version 2>/dev/null || echo "unknown")
            echo -e "${GREEN}✅ $tool: $(echo "$version" | head -1)${NC}"
            installed_count=$((installed_count + 1))
        else
            echo -e "${RED}❌ $tool: not found${NC}"
            missing_tools+=("$tool")
        fi
    done

    echo ""
    echo -e "${BLUE}Installation Summary:${NC}"
    echo -e "  ✅ Installed: $installed_count/${#tools[@]} tools"

    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo -e "  ❌ Missing: ${missing_tools[*]}"
        return 1
    else
        echo -e "  🎉 All tools installed successfully!"
        return 0
    fi
}

# Function to create setup summary
create_setup_summary() {
    local summary_file="$PROJECT_ROOT/.reports/setup-summary.txt"

    {
        echo "CI Environment Setup Summary"
        echo "============================"
        echo "Date: $(date)"
        echo "OS: $OS"
        echo ""

        echo "Installed Tools:"
        for tool in kubectl kustomize helm terraform tfsec trivy conftest yq checkov yamllint markdownlint; do
            if command -v "$tool" &> /dev/null; then
                echo "  ✅ $tool"
            else
                echo "  ❌ $tool (missing)"
            fi
        done

        echo ""
        echo "Next Steps:"
        echo "  1. Source your shell profile or restart terminal"
        echo "  2. Run 'make verify' to test all CI tools"
        echo "  3. Configure pre-commit hooks if needed"
        echo "  4. Run initial CI validation with 'make ci'"

    } > "$summary_file"

    echo -e "${BLUE}📋 Setup summary saved to: $summary_file${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}Starting CI environment setup...${NC}"
    echo "Project: $PROJECT_ROOT"
    echo ""

    detect_os

    # Run setup steps
    install_system_dependencies
    echo ""

    install_ci_tools
    echo ""

    install_python_tools
    echo ""

    install_nodejs_tools
    echo ""

    create_directories
    echo ""

    setup_git_hooks
    echo ""

    if verify_installation; then
        create_setup_summary
        echo ""
        echo -e "${GREEN}🎉 CI environment setup completed successfully!${NC}"
        echo -e "${BLUE}Please restart your terminal or source your profile to use the new tools.${NC}"
        return 0
    else
        echo -e "${RED}❌ CI environment setup completed with some missing tools.${NC}"
        echo -e "${YELLOW}Please install missing tools manually or run the script again.${NC}"
        return 1
    fi
}

# Run main function
main "$@"
