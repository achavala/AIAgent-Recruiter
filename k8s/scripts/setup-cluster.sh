#!/bin/bash

# AI Agent Recruiter - EKS Cluster Setup Script
# This script sets up the entire EKS infrastructure using Terraform

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(cd "$SCRIPT_DIR/../terraform" && pwd)"
AWS_REGION=${AWS_REGION:-us-east-1}
ENVIRONMENT=${ENVIRONMENT:-development}
PROJECT_NAME="ai-agent-recruiter"

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
    
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed"
        exit 1
    fi
    
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed"
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
        exit 1
    fi
    
    if ! command -v helm &> /dev/null; then
        log_error "Helm is not installed"
        exit 1
    fi
    
    # Check if logged in to AWS
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "Not logged in to AWS. Please run 'aws configure' or set AWS credentials"
        exit 1
    fi
    
    log_success "All requirements met"
}

# Create S3 bucket for Terraform state
create_terraform_state_bucket() {
    BUCKET_NAME="${PROJECT_NAME}-terraform-state-${ENVIRONMENT}"
    DYNAMODB_TABLE="${PROJECT_NAME}-terraform-locks-${ENVIRONMENT}"
    
    log_info "Creating S3 bucket for Terraform state: $BUCKET_NAME"
    
    # Create S3 bucket
    if ! aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
        aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$AWS_REGION" \
            --create-bucket-configuration LocationConstraint="$AWS_REGION" 2>/dev/null || \
        aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$AWS_REGION" 2>/dev/null
        
        # Enable versioning
        aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" \
            --versioning-configuration Status=Enabled
        
        # Enable encryption
        aws s3api put-bucket-encryption --bucket "$BUCKET_NAME" \
            --server-side-encryption-configuration '{
                "Rules": [
                    {
                        "ApplyServerSideEncryptionByDefault": {
                            "SSEAlgorithm": "AES256"
                        }
                    }
                ]
            }'
        
        # Block public access
        aws s3api put-public-access-block --bucket "$BUCKET_NAME" \
            --public-access-block-configuration \
            BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
        
        log_success "S3 bucket created: $BUCKET_NAME"
    else
        log_info "S3 bucket already exists: $BUCKET_NAME"
    fi
    
    # Create DynamoDB table for state locking
    if ! aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION" &>/dev/null; then
        log_info "Creating DynamoDB table for state locking: $DYNAMODB_TABLE"
        aws dynamodb create-table \
            --table-name "$DYNAMODB_TABLE" \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
            --region "$AWS_REGION"
        
        # Wait for table to be created
        aws dynamodb wait table-exists --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION"
        log_success "DynamoDB table created: $DYNAMODB_TABLE"
    else
        log_info "DynamoDB table already exists: $DYNAMODB_TABLE"
    fi
}

# Generate Terraform variables file
generate_terraform_vars() {
    log_info "Generating Terraform variables file..."
    
    cat > "$TERRAFORM_DIR/terraform.tfvars" << EOF
# Environment Configuration
environment = "$ENVIRONMENT"
aws_region  = "$AWS_REGION"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"
private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

# EKS Configuration
node_instance_types = ["m5.large", "m5.xlarge"]
node_group_min_size = 1
node_group_max_size = 10
node_group_desired_size = 3

spot_instance_types = ["m5.large", "m5.xlarge", "m4.large", "m4.xlarge"]
spot_node_group_min_size = 0
spot_node_group_max_size = 5
spot_node_group_desired_size = 2

# RDS Configuration
create_rds = true
rds_instance_class = "db.t3.micro"
rds_allocated_storage = 20
rds_max_allocated_storage = 100
rds_password = "$(openssl rand -base64 32)"

# ElastiCache Configuration
create_elasticache = true
redis_node_type = "cache.t3.micro"
redis_num_cache_nodes = 1

# Application Configuration
openai_api_key = "your_openai_api_key_here"
email_username = "your_email@example.com"
email_password = "your_email_password_here"
jwt_secret_key = "$(openssl rand -base64 64)"
encryption_key = "$(openssl rand -base64 32)"

# DNS Configuration
create_route53_zone = false
domain_name = "ai-agent-recruiter.com"
create_acm_certificate = false

# Security Configuration
create_waf = true

# Cost Optimization
single_nat_gateway = $([ "$ENVIRONMENT" = "production" ] && echo "false" || echo "true")
enable_cost_optimization = true

# Environment-specific overrides
$(case $ENVIRONMENT in
    production)
        echo "# Production-specific configuration"
        echo "node_group_desired_size = 3"
        echo "rds_instance_class = \"db.t3.small\""
        echo "redis_node_type = \"cache.t3.small\""
        echo "redis_num_cache_nodes = 2"
        echo "create_route53_zone = true"
        echo "create_acm_certificate = true"
        echo "single_nat_gateway = false"
        ;;
    staging)
        echo "# Staging-specific configuration"
        echo "node_group_desired_size = 2"
        echo "rds_instance_class = \"db.t3.micro\""
        echo "redis_node_type = \"cache.t3.micro\""
        echo "redis_num_cache_nodes = 1"
        echo "single_nat_gateway = true"
        ;;
    development)
        echo "# Development-specific configuration"
        echo "node_group_desired_size = 1"
        echo "rds_instance_class = \"db.t3.micro\""
        echo "redis_node_type = \"cache.t3.micro\""
        echo "redis_num_cache_nodes = 1"
        echo "single_nat_gateway = true"
        echo "create_rds = false"
        echo "create_elasticache = false"
        ;;
esac)
EOF
    
    log_success "Terraform variables file generated"
}

# Update Terraform backend configuration
update_terraform_backend() {
    log_info "Updating Terraform backend configuration..."
    
    BUCKET_NAME="${PROJECT_NAME}-terraform-state-${ENVIRONMENT}"
    DYNAMODB_TABLE="${PROJECT_NAME}-terraform-locks-${ENVIRONMENT}"
    
    # Update main.tf with correct backend configuration
    sed -i.bak "s/bucket = \".*\"/bucket = \"$BUCKET_NAME\"/" "$TERRAFORM_DIR/main.tf"
    sed -i.bak "s/dynamodb_table = \".*\"/dynamodb_table = \"$DYNAMODB_TABLE\"/" "$TERRAFORM_DIR/main.tf"
    sed -i.bak "s/region = \".*\"/region = \"$AWS_REGION\"/" "$TERRAFORM_DIR/main.tf"
    
    # Update key based on environment
    sed -i.bak "s/key    = \".*\"/key    = \"$ENVIRONMENT\/terraform.tfstate\"/" "$TERRAFORM_DIR/main.tf"
    
    log_success "Terraform backend configuration updated"
}

# Initialize Terraform
init_terraform() {
    log_info "Initializing Terraform..."
    cd "$TERRAFORM_DIR"
    terraform init
    log_success "Terraform initialized"
}

# Plan Terraform deployment
plan_terraform() {
    log_info "Planning Terraform deployment..."
    cd "$TERRAFORM_DIR"
    terraform plan -out=tfplan
    log_success "Terraform plan completed"
}

# Apply Terraform deployment
apply_terraform() {
    log_info "Applying Terraform deployment..."
    cd "$TERRAFORM_DIR"
    terraform apply tfplan
    log_success "Terraform deployment completed"
}

# Install Kubernetes addons
install_k8s_addons() {
    log_info "Installing Kubernetes addons..."
    
    # Get cluster name from Terraform output
    CLUSTER_NAME=$(terraform output -raw cluster_id)
    
    # Configure kubectl
    aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"
    
    # Install AWS Load Balancer Controller
    log_info "Installing AWS Load Balancer Controller..."
    
    # Create IAM role for AWS Load Balancer Controller
    eksctl create iamserviceaccount \
        --cluster="$CLUSTER_NAME" \
        --namespace=kube-system \
        --name=aws-load-balancer-controller \
        --role-name "AmazonEKSLoadBalancerControllerRole" \
        --attach-policy-arn=arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess \
        --approve || true
    
    # Add EKS chart repo
    helm repo add eks https://aws.github.io/eks-charts
    helm repo update
    
    # Install AWS Load Balancer Controller
    helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
        -n kube-system \
        --set clusterName="$CLUSTER_NAME" \
        --set serviceAccount.create=false \
        --set serviceAccount.name=aws-load-balancer-controller
    
    # Install EBS CSI Driver
    log_info "Installing EBS CSI Driver..."
    kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=master"
    
    # Install Metrics Server
    log_info "Installing Metrics Server..."
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    
    # Install Cluster Autoscaler
    log_info "Installing Cluster Autoscaler..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
    
    # Patch Cluster Autoscaler deployment
    kubectl patch deployment cluster-autoscaler \
        -n kube-system \
        -p '{"spec":{"template":{"metadata":{"annotations":{"cluster-autoscaler.kubernetes.io/safe-to-evict":"false"}}}}}'
    
    kubectl patch deployment cluster-autoscaler \
        -n kube-system \
        -p '{"spec":{"template":{"spec":{"containers":[{"name":"cluster-autoscaler","command":["./cluster-autoscaler","--v=4","--stderrthreshold=info","--cloud-provider=aws","--skip-nodes-with-local-storage=false","--expander=least-waste","--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/'$CLUSTER_NAME'"]}]}}}}'
    
    log_success "Kubernetes addons installed"
}

# Display cluster information
display_cluster_info() {
    log_info "Gathering cluster information..."
    
    cd "$TERRAFORM_DIR"
    
    echo ""
    echo "=== Cluster Information ==="
    echo "Cluster Name: $(terraform output -raw cluster_id)"
    echo "Cluster Endpoint: $(terraform output -raw cluster_endpoint)"
    echo "AWS Region: $(terraform output -raw aws_region)"
    echo "VPC ID: $(terraform output -raw vpc_id)"
    
    if terraform output rds_endpoint &>/dev/null; then
        echo "RDS Endpoint: $(terraform output -raw rds_endpoint)"
    fi
    
    if terraform output elasticache_endpoint &>/dev/null; then
        echo "ElastiCache Endpoint: $(terraform output -raw elasticache_endpoint)"
    fi
    
    echo ""
    echo "=== Connection Commands ==="
    echo "Configure kubectl: $(terraform output -raw kubectl_config_command)"
    echo "Test connection: kubectl get nodes"
    echo "Deploy application: ./k8s/scripts/deploy.sh --environment $ENVIRONMENT"
    
    echo ""
    echo "=== Useful Commands ==="
    echo "View pods: kubectl get pods -A"
    echo "View services: kubectl get services -A"
    echo "View logs: kubectl logs -f deployment/aws-load-balancer-controller -n kube-system"
}

# Destroy infrastructure
destroy_infrastructure() {
    log_warning "Destroying infrastructure..."
    read -p "Are you sure you want to destroy the infrastructure? (yes/no): " -r
    if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        cd "$TERRAFORM_DIR"
        terraform destroy -auto-approve
        log_success "Infrastructure destroyed"
    else
        log_info "Infrastructure destruction cancelled"
    fi
}

# Display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --environment ENV    Set environment (development, staging, production)"
    echo "  --region REGION      Set AWS region (default: us-east-1)"
    echo "  --destroy            Destroy infrastructure"
    echo "  --plan-only          Only run terraform plan"
    echo "  --skip-addons        Skip Kubernetes addons installation"
    echo "  --help               Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  AWS_REGION           AWS region (default: us-east-1)"
    echo "  ENVIRONMENT          Environment (default: development)"
    echo ""
    echo "Examples:"
    echo "  $0 --environment production --region us-west-2"
    echo "  $0 --plan-only --environment staging"
    echo "  $0 --destroy --environment development"
}

# Parse command line arguments
DESTROY=false
PLAN_ONLY=false
SKIP_ADDONS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --region)
            AWS_REGION="$2"
            shift 2
            ;;
        --destroy)
            DESTROY=true
            shift
            ;;
        --plan-only)
            PLAN_ONLY=true
            shift
            ;;
        --skip-addons)
            SKIP_ADDONS=true
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
    log_info "Starting EKS cluster setup..."
    log_info "Environment: $ENVIRONMENT"
    log_info "AWS Region: $AWS_REGION"
    
    check_requirements
    
    if [[ "$DESTROY" == "true" ]]; then
        destroy_infrastructure
        return 0
    fi
    
    create_terraform_state_bucket
    generate_terraform_vars
    update_terraform_backend
    init_terraform
    plan_terraform
    
    if [[ "$PLAN_ONLY" == "true" ]]; then
        log_info "Plan-only mode. Exiting without applying changes."
        return 0
    fi
    
    apply_terraform
    
    if [[ "$SKIP_ADDONS" != "true" ]]; then
        install_k8s_addons
    fi
    
    display_cluster_info
    
    log_success "EKS cluster setup completed successfully!"
    
    echo ""
    echo "Next steps:"
    echo "1. Configure kubectl: aws eks update-kubeconfig --region $AWS_REGION --name \$(terraform output -raw cluster_id)"
    echo "2. Deploy application: ./k8s/scripts/deploy.sh --environment $ENVIRONMENT"
    echo "3. Monitor cluster: kubectl get nodes && kubectl get pods -A"
    echo "4. Access application: Check ingress for external IP"
}

# Run main function
main "$@"