#!/bin/bash

set -euo pipefail

# CI Cleanup Script - Remove temporary files and artifacts
echo "🧹 Cleaning up CI artifacts..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to clean reports
clean_reports() {
    echo -e "${BLUE}📊 Cleaning report files...${NC}"

    local reports_dir="$PROJECT_ROOT/.reports"

    if [ -d "$reports_dir" ]; then
        local report_count=$(find "$reports_dir" -type f | wc -l)
        echo -e "${BLUE}Found $report_count report files${NC}"

        if [ "$report_count" -gt 0 ]; then
            # Archive old reports if requested
            if [ "${ARCHIVE_REPORTS:-false}" = "true" ]; then
                local archive_dir="$PROJECT_ROOT/.reports-archive/$(date +%Y-%m-%d_%H-%M-%S)"
                mkdir -p "$archive_dir"
                cp -r "$reports_dir"/* "$archive_dir/" 2>/dev/null || true
                echo -e "${GREEN}✅ Reports archived to: $archive_dir${NC}"
            fi

            # Clean reports
            rm -rf "$reports_dir"/*
            echo -e "${GREEN}✅ Cleaned $report_count report files${NC}"
        else
            echo -e "${YELLOW}No report files to clean${NC}"
        fi
    else
        echo -e "${YELLOW}No reports directory found${NC}"
    fi
}

# Function to clean cache files
clean_cache() {
    echo -e "${BLUE}💾 Cleaning cache files...${NC}"

    local cache_dirs=(
        "$PROJECT_ROOT/.cache"
        "$PROJECT_ROOT/tmp"
        "$PROJECT_ROOT/.terraform"
        "$PROJECT_ROOT/.pytest_cache"
        "$PROJECT_ROOT/.mypy_cache"
        "$PROJECT_ROOT/node_modules/.cache"
        "/tmp/.cache/trivy"
    )

    local cleaned_count=0

    for cache_dir in "${cache_dirs[@]}"; do
        if [ -d "$cache_dir" ]; then
            local cache_size=$(du -sh "$cache_dir" 2>/dev/null | cut -f1)
            rm -rf "$cache_dir"
            echo -e "${GREEN}✅ Cleaned cache: $cache_dir ($cache_size)${NC}"
            cleaned_count=$((cleaned_count + 1))
        fi
    done

    # Clean Terraform cache in all environments
    find "$PROJECT_ROOT/terraform" -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
    find "$PROJECT_ROOT/terraform" -name "*.tfstate.backup" -type f -delete 2>/dev/null || true
    find "$PROJECT_ROOT/terraform" -name "terraform.tfplan" -type f -delete 2>/dev/null || true

    echo -e "${GREEN}✅ Cleaned $cleaned_count cache directories${NC}"
}

# Function to clean temporary files
clean_temp_files() {
    echo -e "${BLUE}🗑️ Cleaning temporary files...${NC}"

    local temp_patterns=(
        "*.tmp"
        "*.temp"
        "*.log"
        "*.pid"
        "*~"
        ".DS_Store"
        "Thumbs.db"
    )

    local temp_count=0

    for pattern in "${temp_patterns[@]}"; do
        local files=$(find "$PROJECT_ROOT" -name "$pattern" -type f 2>/dev/null | head -100)
        if [ -n "$files" ]; then
            while IFS= read -r file; do
                if [ -n "$file" ]; then
                    rm -f "$file"
                    temp_count=$((temp_count + 1))
                fi
            done <<< "$files"
        fi
    done

    echo -e "${GREEN}✅ Cleaned $temp_count temporary files${NC}"
}

# Function to clean Docker artifacts (if Docker is available)
clean_docker() {
    if command -v docker &> /dev/null; then
        echo -e "${BLUE}🐳 Cleaning Docker artifacts...${NC}"

        # Clean dangling images
        local dangling_images=$(docker images -f "dangling=true" -q 2>/dev/null | wc -l)
        if [ "$dangling_images" -gt 0 ]; then
            docker image prune -f &> /dev/null
            echo -e "${GREEN}✅ Cleaned $dangling_images dangling Docker images${NC}"
        fi

        # Clean build cache
        if docker builder prune -f &> /dev/null; then
            echo -e "${GREEN}✅ Cleaned Docker build cache${NC}"
        fi

        # Clean volumes (only if CLEAN_DOCKER_VOLUMES=true)
        if [ "${CLEAN_DOCKER_VOLUMES:-false}" = "true" ]; then
            local unused_volumes=$(docker volume ls -f dangling=true -q 2>/dev/null | wc -l)
            if [ "$unused_volumes" -gt 0 ]; then
                docker volume prune -f &> /dev/null
                echo -e "${GREEN}✅ Cleaned $unused_volumes unused Docker volumes${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}Docker not available, skipping Docker cleanup${NC}"
    fi
}

# Function to clean Git artifacts
clean_git() {
    echo -e "${BLUE}🔧 Cleaning Git artifacts...${NC}"

    cd "$PROJECT_ROOT"

    # Clean Git cache
    if git rev-parse --git-dir &> /dev/null; then
        # Run git gc to optimize repository
        git gc --quiet 2>/dev/null || true
        echo -e "${GREEN}✅ Optimized Git repository${NC}"

        # Clean untracked files (with confirmation)
        local untracked_count=$(git ls-files --others --exclude-standard | wc -l)
        if [ "$untracked_count" -gt 0 ]; then
            if [ "${CLEAN_UNTRACKED:-false}" = "true" ]; then
                git clean -fd
                echo -e "${GREEN}✅ Cleaned $untracked_count untracked files${NC}"
            else
                echo -e "${YELLOW}Found $untracked_count untracked files (set CLEAN_UNTRACKED=true to remove)${NC}"
            fi
        fi
    fi
}

# Function to clean package manager caches
clean_package_managers() {
    echo -e "${BLUE}📦 Cleaning package manager caches...${NC}"

    # Clean npm cache
    if command -v npm &> /dev/null; then
        npm cache clean --force &> /dev/null || true
        echo -e "${GREEN}✅ Cleaned npm cache${NC}"
    fi

    # Clean pip cache
    if command -v pip3 &> /dev/null; then
        pip3 cache purge &> /dev/null || true
        echo -e "${GREEN}✅ Cleaned pip cache${NC}"
    fi

    # Clean yarn cache
    if command -v yarn &> /dev/null; then
        yarn cache clean &> /dev/null || true
        echo -e "${GREEN}✅ Cleaned yarn cache${NC}"
    fi

    # Clean go cache
    if command -v go &> /dev/null; then
        go clean -cache &> /dev/null || true
        echo -e "${GREEN}✅ Cleaned Go cache${NC}"
    fi
}

# Function to display cleanup summary
show_cleanup_summary() {
    echo -e "${BLUE}📋 Cleanup Summary${NC}"

    local summary_file="$PROJECT_ROOT/.reports/cleanup-summary.txt"
    mkdir -p "$(dirname "$summary_file")"

    {
        echo "CI Cleanup Summary"
        echo "=================="
        echo "Date: $(date)"
        echo ""

        echo "Cleaned Components:"
        echo "  ✅ Report files"
        echo "  ✅ Cache directories"
        echo "  ✅ Temporary files"
        echo "  ✅ Git artifacts"
        echo "  ✅ Package manager caches"

        if command -v docker &> /dev/null; then
            echo "  ✅ Docker artifacts"
        fi

        echo ""
        echo "Current Disk Usage:"
        du -sh "$PROJECT_ROOT" 2>/dev/null | sed 's/^/  /'

        echo ""
        echo "Environment Variables Used:"
        echo "  ARCHIVE_REPORTS=${ARCHIVE_REPORTS:-false}"
        echo "  CLEAN_DOCKER_VOLUMES=${CLEAN_DOCKER_VOLUMES:-false}"
        echo "  CLEAN_UNTRACKED=${CLEAN_UNTRACKED:-false}"

    } > "$summary_file"

    cat "$summary_file"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -a, --archive          Archive reports before cleaning"
    echo "  -d, --docker-volumes   Clean Docker volumes (dangerous)"
    echo "  -u, --untracked        Clean Git untracked files"
    echo "  -f, --full             Full cleanup (includes all options)"
    echo ""
    echo "Environment Variables:"
    echo "  ARCHIVE_REPORTS=true   Archive reports before cleaning"
    echo "  CLEAN_DOCKER_VOLUMES=true  Clean Docker volumes"
    echo "  CLEAN_UNTRACKED=true   Clean Git untracked files"
    echo ""
    echo "Examples:"
    echo "  $0                     Basic cleanup"
    echo "  $0 --archive          Archive reports before cleaning"
    echo "  $0 --full             Full cleanup with all options"
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -a|--archive)
                export ARCHIVE_REPORTS=true
                shift
                ;;
            -d|--docker-volumes)
                export CLEAN_DOCKER_VOLUMES=true
                shift
                ;;
            -u|--untracked)
                export CLEAN_UNTRACKED=true
                shift
                ;;
            -f|--full)
                export ARCHIVE_REPORTS=true
                export CLEAN_DOCKER_VOLUMES=true
                export CLEAN_UNTRACKED=true
                shift
                ;;
            *)
                echo -e "${RED}❌ Unknown option: $1${NC}"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Main execution
main() {
    echo -e "${BLUE}Starting CI cleanup...${NC}"
    echo "Project: $PROJECT_ROOT"
    echo ""

    # Show current disk usage
    echo -e "${BLUE}Current disk usage:${NC}"
    du -sh "$PROJECT_ROOT" 2>/dev/null | sed 's/^/  /' || echo "  Unable to calculate"
    echo ""

    # Run cleanup steps
    clean_reports
    echo ""

    clean_cache
    echo ""

    clean_temp_files
    echo ""

    clean_git
    echo ""

    clean_package_managers
    echo ""

    clean_docker
    echo ""

    # Show summary
    show_cleanup_summary

    echo ""
    echo -e "${GREEN}🎉 CI cleanup completed successfully!${NC}"
}

# Parse arguments and run main
parse_arguments "$@"
main
