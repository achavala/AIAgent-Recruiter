#!/bin/bash

# AI Agent Recruiter - Docker Build and Push Script
# This script builds Docker images and pushes them to ECR

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
AWS_REGION=${AWS_REGION:-us-east-1}
ECR_REPOSITORY_NAME=${ECR_REPOSITORY_NAME:-ai-agent-recruiter}
VERSION=${VERSION:-$(git rev-parse --short HEAD)}
ENVIRONMENT=${ENVIRONMENT:-development}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_requirements() {
    log_info "Checking requirements..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed"
        exit 1
    fi
    
    # Check if logged in to AWS
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "Not logged in to AWS. Please run 'aws configure' or set AWS credentials"
        exit 1
    fi
    
    log_success "All requirements met"
}

# Get AWS account ID
get_aws_account_id() {
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
    log_info "AWS Account ID: $AWS_ACCOUNT_ID"
}

# Create ECR repositories if they don't exist
create_ecr_repositories() {
    log_info "Creating ECR repositories..."
    
    # Backend repository
    if ! aws ecr describe-repositories --repository-names "${ECR_REPOSITORY_NAME}-backend" --region "$AWS_REGION" &> /dev/null; then
        log_info "Creating backend ECR repository..."
        aws ecr create-repository \
            --repository-name "${ECR_REPOSITORY_NAME}-backend" \
            --region "$AWS_REGION" \
            --image-scanning-configuration scanOnPush=true \
            --encryption-configuration encryptionType=AES256
        log_success "Backend ECR repository created"
    else
        log_info "Backend ECR repository already exists"
    fi
    
    # Frontend repository
    if ! aws ecr describe-repositories --repository-names "${ECR_REPOSITORY_NAME}-frontend" --region "$AWS_REGION" &> /dev/null; then
        log_info "Creating frontend ECR repository..."
        aws ecr create-repository \
            --repository-name "${ECR_REPOSITORY_NAME}-frontend" \
            --region "$AWS_REGION" \
            --image-scanning-configuration scanOnPush=true \
            --encryption-configuration encryptionType=AES256
        log_success "Frontend ECR repository created"
    else
        log_info "Frontend ECR repository already exists"
    fi
}

# Login to ECR
login_to_ecr() {
    log_info "Logging in to ECR..."
    aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY"
    log_success "Successfully logged in to ECR"
}

# Build Docker images
build_images() {
    log_info "Building Docker images..."
    
    # Build backend image
    log_info "Building backend image..."
    cd "$PROJECT_ROOT/backend"
    docker build -t "${ECR_REPOSITORY_NAME}-backend:${VERSION}" .
    docker tag "${ECR_REPOSITORY_NAME}-backend:${VERSION}" "${ECR_REGISTRY}/${ECR_REPOSITORY_NAME}-backend:${VERSION}"
    docker tag "${ECR_REPOSITORY_NAME}-backend:${VERSION}" "${ECR_REGISTRY}/${ECR_REPOSITORY_NAME}-backend:${ENVIRONMENT}"
    docker tag "${ECR_REPOSITORY_NAME}-backend:${VERSION}" "${ECR_REGISTRY}/${ECR_REPOSITORY_NAME}-backend:latest"
    log_success "Backend image built"
    
    # Build frontend image
    log_info "Building frontend image..."
    cd "$PROJECT_ROOT/frontend"
    docker build -t "${ECR_REPOSITORY_NAME}-frontend:${VERSION}" .
    docker tag "${ECR_REPOSITORY_NAME}-frontend:${VERSION}" "${ECR_REGISTRY}/${ECR_REPOSITORY_NAME}-frontend:${VERSION}"
    docker tag "${ECR_REPOSITORY_NAME}-frontend:${VERSION}" "${ECR_REGISTRY}/${ECR_REPOSITORY_NAME}-frontend:${ENVIRONMENT}"
    docker tag "${ECR_REPOSITORY_NAME}-frontend:${VERSION}" "${ECR_REGISTRY}/${ECR_REPOSITORY_NAME}-frontend:latest"
    log_success "Frontend image built"
    
    cd "$PROJECT_ROOT"
}

# Push Docker images to ECR
push_images() {
    log_info "Pushing Docker images to ECR..."
    
    # Push backend image
    log_info "Pushing backend image..."
    docker push "${ECR_REGISTRY}/${ECR_REPOSITORY_NAME}-backend:${VERSION}"
    docker push "${ECR_REGISTRY}/${ECR_REPOSITORY_NAME}-backend:${ENVIRONMENT}"
    docker push "${ECR_REGISTRY}/${ECR_REPOSITORY_NAME}-backend:latest"
    log_success "Backend image pushed"
    
    # Push frontend image
    log_info "Pushing frontend image..."
    docker push "${ECR_REGISTRY}/${ECR_REPOSITORY_NAME}-frontend:${VERSION}"
    docker push "${ECR_REGISTRY}/${ECR_REPOSITORY_NAME}-frontend:${ENVIRONMENT}"
    docker push "${ECR_REGISTRY}/${ECR_REPOSITORY_NAME}-frontend:latest"
    log_success "Frontend image pushed"
}

# Scan images for vulnerabilities
scan_images() {
    log_info "Scanning images for vulnerabilities..."
    
    # Scan backend image
    log_info "Scanning backend image..."
    aws ecr start-image-scan \
        --repository-name "${ECR_REPOSITORY_NAME}-backend" \
        --image-id imageTag="${VERSION}" \
        --region "$AWS_REGION" || true
    
    # Scan frontend image
    log_info "Scanning frontend image..."
    aws ecr start-image-scan \
        --repository-name "${ECR_REPOSITORY_NAME}-frontend" \
        --image-id imageTag="${VERSION}" \
        --region "$AWS_REGION" || true
    
    log_success "Image scans initiated"
}

# Clean up local images
cleanup() {
    if [[ "$1" == "--cleanup" ]]; then
        log_info "Cleaning up local images..."
        docker rmi "${ECR_REPOSITORY_NAME}-backend:${VERSION}" || true
        docker rmi "${ECR_REPOSITORY_NAME}-frontend:${VERSION}" || true
        docker rmi "${ECR_REGISTRY}/${ECR_REPOSITORY_NAME}-backend:${VERSION}" || true
        docker rmi "${ECR_REGISTRY}/${ECR_REPOSITORY_NAME}-backend:${ENVIRONMENT}" || true
        docker rmi "${ECR_REGISTRY}/${ECR_REPOSITORY_NAME}-backend:latest" || true
        docker rmi "${ECR_REGISTRY}/${ECR_REPOSITORY_NAME}-frontend:${VERSION}" || true
        docker rmi "${ECR_REGISTRY}/${ECR_REPOSITORY_NAME}-frontend:${ENVIRONMENT}" || true
        docker rmi "${ECR_REGISTRY}/${ECR_REPOSITORY_NAME}-frontend:latest" || true
        log_success "Local images cleaned up"
    fi
}

# Display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --environment ENV    Set environment (development, staging, production)"
    echo "  --version VERSION    Set version tag (default: git commit hash)"
    echo "  --region REGION      Set AWS region (default: us-east-1)"
    echo "  --cleanup            Clean up local images after push"
    echo "  --skip-scan          Skip vulnerability scanning"
    echo "  --help               Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  AWS_REGION           AWS region (default: us-east-1)"
    echo "  ECR_REPOSITORY_NAME  ECR repository name (default: ai-agent-recruiter)"
    echo "  VERSION              Version tag (default: git commit hash)"
    echo "  ENVIRONMENT          Environment (default: development)"
    echo ""
    echo "Examples:"
    echo "  $0 --environment production --version v1.0.0"
    echo "  $0 --cleanup"
    echo "  $0 --skip-scan --environment staging"
}

# Parse command line arguments
SKIP_SCAN=false
CLEANUP_IMAGES=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        --region)
            AWS_REGION="$2"
            shift 2
            ;;
        --cleanup)
            CLEANUP_IMAGES=true
            shift
            ;;
        --skip-scan)
            SKIP_SCAN=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    log_info "Starting Docker build and push process..."
    log_info "Environment: $ENVIRONMENT"
    log_info "Version: $VERSION"
    log_info "AWS Region: $AWS_REGION"
    log_info "ECR Repository: $ECR_REPOSITORY_NAME"
    
    check_requirements
    get_aws_account_id
    create_ecr_repositories
    login_to_ecr
    build_images
    push_images
    
    if [[ "$SKIP_SCAN" == false ]]; then
        scan_images
    fi
    
    cleanup "$CLEANUP_IMAGES"
    
    log_success "Docker build and push completed successfully!"
    log_info "Backend Image: ${ECR_REGISTRY}/${ECR_REPOSITORY_NAME}-backend:${VERSION}"
    log_info "Frontend Image: ${ECR_REGISTRY}/${ECR_REPOSITORY_NAME}-frontend:${VERSION}"
    
    echo ""
    echo "Next steps:"
    echo "1. Update Kubernetes manifests with new image URIs"
    echo "2. Run deployment script: ./k8s/scripts/deploy.sh"
    echo "3. Monitor deployment: kubectl get pods -n ai-agent-recruiter"
}

# Run main function
main "$@"