#!/bin/bash
# Docker CI Build and Test Script
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCKER_REPO="${DOCKER_REPO:-observability-platform-ci}"
DOCKER_TAG="${DOCKER_TAG:-latest}"
BUILD_CACHE="${BUILD_CACHE:-true}"

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1${NC}"
}

# Function to build Docker image
build_image() {
    local target="$1"
    local tag="$2"

    log "Building Docker image: ${DOCKER_REPO}:${tag} (target: ${target})"

    # Build arguments
    BUILD_ARGS=""
    if [[ "${BUILD_CACHE}" == "false" ]]; then
        BUILD_ARGS="--no-cache"
    fi

    # Build the image
    if docker build ${BUILD_ARGS} \
        --target "${target}" \
        --tag "${DOCKER_REPO}:${tag}" \
        --file Dockerfile.ci \
        --progress=plain \
        .; then
        success "Successfully built ${DOCKER_REPO}:${tag}"
        return 0
    else
        error "Failed to build ${DOCKER_REPO}:${tag}"
        return 1
    fi
}

# Function to test image
test_image() {
    local tag="$1"
    local test_command="$2"

    log "Testing image: ${DOCKER_REPO}:${tag}"

    if docker run --rm \
        --volume "$(pwd):/workspace:ro" \
        --workdir /workspace \
        "${DOCKER_REPO}:${tag}" \
        ${test_command}; then
        success "Image test passed: ${DOCKER_REPO}:${tag}"
        return 0
    else
        error "Image test failed: ${DOCKER_REPO}:${tag}"
        return 1
    fi
}

# Function to show image info
show_image_info() {
    local tag="$1"

    log "Image information for ${DOCKER_REPO}:${tag}"
    echo "Size: $(docker images --format "table {{.Size}}" ${DOCKER_REPO}:${tag} | tail -n 1)"
    echo "Created: $(docker images --format "table {{.CreatedAt}}" ${DOCKER_REPO}:${tag} | tail -n 1)"

    # Show installed tools
    log "Installed CI tools:"
    docker run --rm "${DOCKER_REPO}:${tag}" sh -c "
        echo 'System Tools:'
        which git jq curl wget || true
        echo
        echo 'Kubernetes Tools:'
        kubectl version --client --short 2>/dev/null || true
        helm version --short 2>/dev/null || true
        kustomize version --short 2>/dev/null || true
        terraform version 2>/dev/null | head -1 || true
        echo
        echo 'Security Tools:'
        trivy --version 2>/dev/null || true
        checkov --version 2>/dev/null || true
        tfsec --version 2>/dev/null || true
        echo
        echo 'Language Tools:'
        python --version 2>/dev/null || true
        node --version 2>/dev/null || true
        go version 2>/dev/null || true
    " 2>/dev/null || warning "Could not retrieve tool versions"
}

# Function to run CI pipeline in container
run_ci_pipeline() {
    log "Running CI pipeline in container"

    # Create reports directory
    mkdir -p .reports

    if docker-compose up --build ci-runner; then
        success "CI pipeline completed successfully"

        # Show report summary if available
        if [[ -d ".reports" ]]; then
            log "CI Reports generated:"
            find .reports -type f -name "*.txt" -o -name "*.json" -o -name "*.html" | head -10
        fi
        return 0
    else
        error "CI pipeline failed"
        return 1
    fi
}

# Function to start development environment
start_dev_environment() {
    log "Starting development environment"

    # Build and start development container
    if docker-compose up --build -d dev-environment; then
        success "Development environment started"
        log "Access the container with: docker-compose exec dev-environment bash"
        log "Stop with: docker-compose down"
        return 0
    else
        error "Failed to start development environment"
        return 1
    fi
}

# Main function
main() {
    local command="${1:-help}"

    case "${command}" in
        "build")
            log "Building all Docker images"
            build_image "ci-environment" "runner" && \
            build_image "dev-environment" "dev" && \
            build_image "final" "latest" && \
            success "All images built successfully"
            ;;

        "build-ci")
            build_image "ci-environment" "runner"
            ;;

        "build-dev")
            build_image "dev-environment" "dev"
            ;;

        "build-all")
            build_image "final" "latest"
            ;;

        "test")
            log "Testing all images"
            test_image "runner" "make --version" && \
            test_image "dev" "python --version" && \
            test_image "latest" "bash --version" && \
            success "All tests passed"
            ;;

        "test-ci")
            test_image "runner" "make lint-yaml"
            ;;

        "info")
            show_image_info "${DOCKER_TAG}"
            ;;

        "ci")
            run_ci_pipeline
            ;;

        "dev")
            start_dev_environment
            ;;

        "clean")
            log "Cleaning up Docker images"
            docker images "${DOCKER_REPO}" --format "table {{.Repository}}:{{.Tag}}" | tail -n +2 | \
                xargs -r docker rmi --force
            success "Cleanup completed"
            ;;

        "help"|*)
            echo "Docker CI Build and Test Script"
            echo
            echo "Usage: $0 <command>"
            echo
            echo "Commands:"
            echo "  build       - Build all Docker images (ci, dev, final)"
            echo "  build-ci    - Build only CI runner image"
            echo "  build-dev   - Build only development image"
            echo "  build-all   - Build final image with all tools"
            echo "  test        - Test all built images"
            echo "  test-ci     - Run CI tests in container"
            echo "  info        - Show image information"
            echo "  ci          - Run full CI pipeline in container"
            echo "  dev         - Start development environment"
            echo "  clean       - Remove all built images"
            echo "  help        - Show this help message"
            echo
            echo "Environment Variables:"
            echo "  DOCKER_REPO - Docker repository name (default: observability-platform-ci)"
            echo "  DOCKER_TAG  - Docker tag (default: latest)"
            echo "  BUILD_CACHE - Use build cache (default: true)"
            echo
            echo "Examples:"
            echo "  $0 build           # Build all images"
            echo "  $0 ci              # Run CI pipeline"
            echo "  $0 dev             # Start development environment"
            echo "  DOCKER_TAG=v1.0.0 $0 build-all"
            ;;
    esac
}

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    error "Docker is not installed or not in PATH"
    exit 1
fi

# Check if docker-compose is available for compose commands
if [[ "$1" == "ci" ]] || [[ "$1" == "dev" ]]; then
    if ! command -v docker-compose &> /dev/null; then
        error "docker-compose is not installed or not in PATH"
        exit 1
    fi
fi

# Run main function
main "$@"
