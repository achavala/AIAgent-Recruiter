#!/bin/bash

# AI Agent Recruiter - Kubernetes Deployment Script
# This script deploys the application to EKS

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFESTS_DIR="$PROJECT_ROOT/manifests"
AWS_REGION=${AWS_REGION:-us-east-1}
CLUSTER_NAME=${CLUSTER_NAME:-ai-agent-recruiter}
NAMESPACE=${NAMESPACE:-ai-agent-recruiter}
ENVIRONMENT=${ENVIRONMENT:-development}
VERSION=${VERSION:-latest}

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
    
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
        exit 1
    fi
    
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed"
        exit 1
    fi
    
    if ! command -v helm &> /dev/null; then
        log_warning "Helm is not installed. Some features may not be available."
    fi
    
    # Check if logged in to AWS
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "Not logged in to AWS. Please run 'aws configure' or set AWS credentials"
        exit 1
    fi
    
    log_success "All requirements met"
}

# Configure kubectl for EKS
configure_kubectl() {
    log_info "Configuring kubectl for EKS cluster..."
    aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"
    
    # Test connection
    if kubectl cluster-info &> /dev/null; then
        log_success "Successfully connected to EKS cluster"
    else
        log_error "Failed to connect to EKS cluster"
        exit 1
    fi
}

# Check if namespace exists and create if not
setup_namespace() {
    log_info "Setting up namespace: $NAMESPACE"
    
    # Map environment to namespace
    case $ENVIRONMENT in
        production)
            NAMESPACE="ai-agent-recruiter"
            ;;
        staging)
            NAMESPACE="ai-agent-recruiter-staging"
            ;;
        development)
            NAMESPACE="ai-agent-recruiter-dev"
            ;;
        *)
            log_warning "Unknown environment: $ENVIRONMENT. Using default namespace."
            NAMESPACE="ai-agent-recruiter-dev"
            ;;
    esac
    
    # Create namespace if it doesn't exist
    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        log_info "Creating namespace: $NAMESPACE"
        kubectl apply -f "$MANIFESTS_DIR/namespace.yaml"
        log_success "Namespace created"
    else
        log_info "Namespace already exists: $NAMESPACE"
    fi
}

# Deploy secrets (with validation)
deploy_secrets() {
    log_info "Deploying secrets..."
    
    # Check if required secrets are set
    if ! kubectl get secret ai-agent-recruiter-secrets -n "$NAMESPACE" &> /dev/null; then
        log_warning "Secrets not found. You need to create secrets manually."
        log_info "Example command to create secrets:"
        cat << EOF
kubectl create secret generic ai-agent-recruiter-secrets -n $NAMESPACE \\
  --from-literal=OPENAI_API_KEY=your_openai_api_key \\
  --from-literal=EMAIL_USERNAME=your_email@example.com \\
  --from-literal=EMAIL_PASSWORD=your_email_password \\
  --from-literal=POSTGRES_PASSWORD=your_postgres_password \\
  --from-literal=JWT_SECRET_KEY=your_jwt_secret_key \\
  --from-literal=ENCRYPTION_KEY=your_encryption_key
EOF
        
        # Apply secret template (with empty values)
        kubectl apply -f "$MANIFESTS_DIR/secret.yaml"
        log_warning "Secret template applied. Please update with actual values."
    else
        log_info "Secrets already exist"
    fi
}

# Deploy ConfigMaps
deploy_configmaps() {
    log_info "Deploying ConfigMaps..."
    kubectl apply -f "$MANIFESTS_DIR/configmap.yaml"
    log_success "ConfigMaps deployed"
}

# Deploy RBAC
deploy_rbac() {
    log_info "Deploying RBAC..."
    kubectl apply -f "$MANIFESTS_DIR/rbac.yaml"
    log_success "RBAC deployed"
}

# Deploy PVCs and storage
deploy_storage() {
    log_info "Deploying storage..."
    kubectl apply -f "$MANIFESTS_DIR/pvc.yaml"
    log_success "Storage deployed"
}

# Update image tags in deployment files
update_image_tags() {
    log_info "Updating image tags..."
    
    # Get AWS account ID
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
    
    # Create temporary deployment files with updated image tags
    mkdir -p "/tmp/ai-agent-recruiter-deploy"
    
    # Backend deployment
    sed "s|your-registry/ai-agent-recruiter-backend:latest|$ECR_REGISTRY/ai-agent-recruiter-backend:$VERSION|g" \
        "$MANIFESTS_DIR/backend-deployment.yaml" > "/tmp/ai-agent-recruiter-deploy/backend-deployment.yaml"
    
    # Frontend deployment
    sed "s|your-registry/ai-agent-recruiter-frontend:latest|$ECR_REGISTRY/ai-agent-recruiter-frontend:$VERSION|g" \
        "$MANIFESTS_DIR/frontend-deployment.yaml" > "/tmp/ai-agent-recruiter-deploy/frontend-deployment.yaml"
    
    log_success "Image tags updated"
}

# Deploy applications
deploy_applications() {
    log_info "Deploying applications..."
    
    # Deploy backend
    log_info "Deploying backend..."
    kubectl apply -f "/tmp/ai-agent-recruiter-deploy/backend-deployment.yaml"
    kubectl apply -f "$MANIFESTS_DIR/backend-service.yaml"
    
    # Deploy frontend
    log_info "Deploying frontend..."
    kubectl apply -f "/tmp/ai-agent-recruiter-deploy/frontend-deployment.yaml"
    kubectl apply -f "$MANIFESTS_DIR/frontend-service.yaml"
    
    log_success "Applications deployed"
}

# Deploy ingress
deploy_ingress() {
    log_info "Deploying ingress..."
    kubectl apply -f "$MANIFESTS_DIR/ingress.yaml"
    log_success "Ingress deployed"
}

# Deploy HPA
deploy_hpa() {
    log_info "Deploying HPA..."
    kubectl apply -f "$MANIFESTS_DIR/hpa.yaml"
    log_success "HPA deployed"
}

# Wait for deployments to be ready
wait_for_deployments() {
    log_info "Waiting for deployments to be ready..."
    
    # Wait for backend deployment
    log_info "Waiting for backend deployment..."
    kubectl wait --for=condition=available --timeout=300s deployment/ai-agent-recruiter-backend -n "$NAMESPACE"
    
    # Wait for frontend deployment
    log_info "Waiting for frontend deployment..."
    kubectl wait --for=condition=available --timeout=300s deployment/ai-agent-recruiter-frontend -n "$NAMESPACE"
    
    log_success "All deployments are ready"
}

# Check deployment status
check_deployment_status() {
    log_info "Checking deployment status..."
    
    echo ""
    echo "=== Namespace Status ==="
    kubectl get namespace "$NAMESPACE"
    
    echo ""
    echo "=== Pods Status ==="
    kubectl get pods -n "$NAMESPACE"
    
    echo ""
    echo "=== Services Status ==="
    kubectl get services -n "$NAMESPACE"
    
    echo ""
    echo "=== Ingress Status ==="
    kubectl get ingress -n "$NAMESPACE"
    
    echo ""
    echo "=== HPA Status ==="
    kubectl get hpa -n "$NAMESPACE"
    
    echo ""
    echo "=== PVC Status ==="
    kubectl get pvc -n "$NAMESPACE"
}

# Get service URLs
get_service_urls() {
    log_info "Getting service URLs..."
    
    # Get ingress URL
    INGRESS_URL=$(kubectl get ingress ai-agent-recruiter-ingress -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Not available yet")
    
    echo ""
    echo "=== Service URLs ==="
    echo "Ingress URL: $INGRESS_URL"
    
    case $ENVIRONMENT in
        production)
            echo "Frontend: https://ai-agent-recruiter.com"
            echo "Backend API: https://api.ai-agent-recruiter.com"
            ;;
        staging)
            echo "Frontend: https://staging.ai-agent-recruiter.com"
            echo "Backend API: https://staging-api.ai-agent-recruiter.com"
            ;;
        development)
            echo "Frontend: https://dev.ai-agent-recruiter.com"
            echo "Backend API: https://dev-api.ai-agent-recruiter.com"
            ;;
    esac
}

# Run database migrations
run_migrations() {
    log_info "Running database migrations..."
    
    # Check if backend pod is running
    BACKEND_POD=$(kubectl get pods -n "$NAMESPACE" -l component=backend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [[ -n "$BACKEND_POD" ]]; then
        log_info "Running migrations in pod: $BACKEND_POD"
        kubectl exec -n "$NAMESPACE" "$BACKEND_POD" -- python -m alembic upgrade head || log_warning "Migration failed or not configured"
    else
        log_warning "Backend pod not found. Skipping migrations."
    fi
}

# Install AWS Load Balancer Controller
install_alb_controller() {
    if [[ "$SKIP_ALB_CONTROLLER" != "true" ]]; then
        log_info "Installing AWS Load Balancer Controller..."
        
        # Add EKS chart repo
        helm repo add eks https://aws.github.io/eks-charts
        helm repo update
        
        # Install AWS Load Balancer Controller
        helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
            -n kube-system \
            --set clusterName="$CLUSTER_NAME" \
            --set serviceAccount.create=false \
            --set serviceAccount.name=aws-load-balancer-controller
        
        log_success "AWS Load Balancer Controller installed"
    fi
}

# Rollback deployment
rollback_deployment() {
    log_info "Rolling back deployment..."
    
    # Rollback backend
    kubectl rollout undo deployment/ai-agent-recruiter-backend -n "$NAMESPACE"
    
    # Rollback frontend
    kubectl rollout undo deployment/ai-agent-recruiter-frontend -n "$NAMESPACE"
    
    log_success "Rollback completed"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up temporary files..."
    rm -rf "/tmp/ai-agent-recruiter-deploy"
}

# Display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --environment ENV       Set environment (development, staging, production)"
    echo "  --version VERSION       Set version tag (default: latest)"
    echo "  --region REGION         Set AWS region (default: us-east-1)"
    echo "  --cluster-name NAME     Set EKS cluster name (default: ai-agent-recruiter)"
    echo "  --skip-alb-controller   Skip AWS Load Balancer Controller installation"
    echo "  --skip-migrations       Skip database migrations"
    echo "  --rollback              Rollback to previous deployment"
    echo "  --dry-run               Show what would be deployed without actually deploying"
    echo "  --help                  Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  AWS_REGION             AWS region (default: us-east-1)"
    echo "  CLUSTER_NAME           EKS cluster name (default: ai-agent-recruiter)"
    echo "  NAMESPACE              Kubernetes namespace (auto-set based on environment)"
    echo "  ENVIRONMENT            Environment (default: development)"
    echo "  VERSION                Version tag (default: latest)"
    echo ""
    echo "Examples:"
    echo "  $0 --environment production --version v1.0.0"
    echo "  $0 --dry-run --environment staging"
    echo "  $0 --rollback --environment production"
}

# Parse command line arguments
SKIP_ALB_CONTROLLER=false
SKIP_MIGRATIONS=false
DRY_RUN=false
ROLLBACK=false

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
        --cluster-name)
            CLUSTER_NAME="$2"
            shift 2
            ;;
        --skip-alb-controller)
            SKIP_ALB_CONTROLLER=true
            shift
            ;;
        --skip-migrations)
            SKIP_MIGRATIONS=true
            shift
            ;;
        --rollback)
            ROLLBACK=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
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
    log_info "Starting Kubernetes deployment..."
    log_info "Environment: $ENVIRONMENT"
    log_info "Version: $VERSION"
    log_info "AWS Region: $AWS_REGION"
    log_info "Cluster Name: $CLUSTER_NAME"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN MODE - No actual deployment will be performed"
        return 0
    fi
    
    check_requirements
    configure_kubectl
    setup_namespace
    
    if [[ "$ROLLBACK" == "true" ]]; then
        rollback_deployment
        check_deployment_status
        return 0
    fi
    
    deploy_secrets
    deploy_configmaps
    deploy_rbac
    deploy_storage
    install_alb_controller
    update_image_tags
    deploy_applications
    deploy_ingress
    deploy_hpa
    wait_for_deployments
    
    if [[ "$SKIP_MIGRATIONS" != "true" ]]; then
        run_migrations
    fi
    
    check_deployment_status
    get_service_urls
    
    log_success "Deployment completed successfully!"
    
    echo ""
    echo "Next steps:"
    echo "1. Wait for ingress to get external IP: kubectl get ingress -n $NAMESPACE"
    echo "2. Configure DNS records to point to the ingress IP"
    echo "3. Monitor application logs: kubectl logs -f deployment/ai-agent-recruiter-backend -n $NAMESPACE"
    echo "4. Check application health: kubectl get pods -n $NAMESPACE"
}

# Trap to cleanup on exit
trap cleanup EXIT

# Run main function
main "$@"