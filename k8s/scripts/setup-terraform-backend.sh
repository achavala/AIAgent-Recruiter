#!/bin/bash

# AI Agent Recruiter - Terraform Backend Setup Script
# This script creates the S3 bucket and DynamoDB table for Terraform state management

set -euo pipefail

# Color codes for output
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

# Configuration
PROJECT_NAME="ai-agent-recruiter"
DEFAULT_REGION="us-east-1"

# Parse command line arguments
ENVIRONMENT=""
AWS_REGION="$DEFAULT_REGION"
FORCE_CREATE=false

usage() {
    echo "Usage: $0 --environment <env> [--region <region>] [--force]"
    echo ""
    echo "Arguments:"
    echo "  --environment    Environment name (development, staging, production)"
    echo "  --region         AWS region (default: $DEFAULT_REGION)"
    echo "  --force          Force creation even if resources exist"
    echo ""
    echo "Example:"
    echo "  $0 --environment development --region us-east-1"
    exit 1
}

# Parse arguments
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
        --force)
            FORCE_CREATE=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required arguments
if [[ -z "$ENVIRONMENT" ]]; then
    log_error "Environment is required"
    usage
fi

if [[ "$ENVIRONMENT" != "development" && "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]]; then
    log_error "Environment must be one of: development, staging, production"
    exit 1
fi

# Set resource names
BUCKET_NAME="${PROJECT_NAME}-terraform-state-${ENVIRONMENT}"
DYNAMODB_TABLE="${PROJECT_NAME}-terraform-locks-${ENVIRONMENT}"

log_info "Setting up Terraform backend for environment: $ENVIRONMENT"
log_info "AWS Region: $AWS_REGION"
log_info "S3 Bucket: $BUCKET_NAME"
log_info "DynamoDB Table: $DYNAMODB_TABLE"

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &>/dev/null; then
    log_error "AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi

# Create S3 bucket
create_s3_bucket() {
    log_info "Creating S3 bucket: $BUCKET_NAME"
    
    # Check if bucket already exists
    if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
        if [[ "$FORCE_CREATE" == "true" ]]; then
            log_warning "Bucket $BUCKET_NAME already exists, continuing due to --force flag"
        else
            log_success "S3 bucket $BUCKET_NAME already exists"
            return 0
        fi
    else
        # Create bucket with proper location constraint
        if [[ "$AWS_REGION" == "us-east-1" ]]; then
            aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$AWS_REGION"
        else
            aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$AWS_REGION" \
                --create-bucket-configuration LocationConstraint="$AWS_REGION"
        fi
        log_success "S3 bucket $BUCKET_NAME created"
    fi
    
    # Enable versioning
    log_info "Enabling versioning on S3 bucket"
    aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" \
        --versioning-configuration Status=Enabled
    
    # Enable encryption
    log_info "Enabling encryption on S3 bucket"
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
    log_info "Blocking public access on S3 bucket"
    aws s3api put-public-access-block --bucket "$BUCKET_NAME" \
        --public-access-block-configuration '{
            "BlockPublicAcls": true,
            "IgnorePublicAcls": true,
            "BlockPublicPolicy": true,
            "RestrictPublicBuckets": true
        }'
    
    # Add lifecycle policy to manage old versions
    log_info "Setting lifecycle policy on S3 bucket"
    aws s3api put-bucket-lifecycle-configuration --bucket "$BUCKET_NAME" \
        --lifecycle-configuration '{
            "Rules": [
                {
                    "ID": "DeleteOldVersions",
                    "Status": "Enabled",
                    "NoncurrentVersionExpiration": {
                        "NoncurrentDays": 90
                    },
                    "AbortIncompleteMultipartUpload": {
                        "DaysAfterInitiation": 7
                    }
                }
            ]
        }'
    
    log_success "S3 bucket configuration completed"
}

# Create DynamoDB table
create_dynamodb_table() {
    log_info "Creating DynamoDB table: $DYNAMODB_TABLE"
    
    # Check if table already exists
    if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION" &>/dev/null; then
        if [[ "$FORCE_CREATE" == "true" ]]; then
            log_warning "DynamoDB table $DYNAMODB_TABLE already exists, continuing due to --force flag"
        else
            log_success "DynamoDB table $DYNAMODB_TABLE already exists"
            return 0
        fi
    else
        # Create table
        aws dynamodb create-table \
            --table-name "$DYNAMODB_TABLE" \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
            --region "$AWS_REGION"
        
        log_info "Waiting for DynamoDB table to become active..."
        aws dynamodb wait table-exists --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION"
        
        log_success "DynamoDB table $DYNAMODB_TABLE created"
    fi
    
    # Enable point-in-time recovery
    log_info "Enabling point-in-time recovery on DynamoDB table"
    aws dynamodb put-backup-policy \
        --table-name "$DYNAMODB_TABLE" \
        --backup-policy BackupPolicyDescription='{
            "PointInTimeRecoveryEnabled": true
        }' \
        --region "$AWS_REGION" || log_warning "Failed to enable point-in-time recovery"
    
    log_success "DynamoDB table configuration completed"
}

# Update Terraform backend configuration
update_terraform_backend() {
    log_info "Updating Terraform backend configuration"
    
    TERRAFORM_DIR="/home/runner/work/AIAgent-Recruiter/AIAgent-Recruiter/k8s/terraform"
    
    # Create backend configuration file
    cat > "$TERRAFORM_DIR/backend.tf" << EOF
# Terraform Backend Configuration
# This file is auto-generated by setup-terraform-backend.sh

terraform {
  backend "s3" {
    bucket         = "$BUCKET_NAME"
    key            = "$ENVIRONMENT/terraform.tfstate"
    region         = "$AWS_REGION"
    dynamodb_table = "$DYNAMODB_TABLE"
    encrypt        = true
  }
}
EOF
    
    log_success "Terraform backend configuration updated"
}

# Display connection information
display_info() {
    echo ""
    echo "=== Terraform Backend Setup Complete ==="
    echo ""
    echo "Environment: $ENVIRONMENT"
    echo "Region: $AWS_REGION"
    echo "S3 Bucket: $BUCKET_NAME"
    echo "DynamoDB Table: $DYNAMODB_TABLE"
    echo ""
    echo "Backend Configuration:"
    echo "  bucket         = \"$BUCKET_NAME\""
    echo "  key            = \"$ENVIRONMENT/terraform.tfstate\""
    echo "  region         = \"$AWS_REGION\""
    echo "  dynamodb_table = \"$DYNAMODB_TABLE\""
    echo "  encrypt        = true"
    echo ""
    echo "Next steps:"
    echo "1. Run 'terraform init' to initialize the backend"
    echo "2. Run 'terraform plan' to see what will be created"
    echo "3. Run 'terraform apply' to create the infrastructure"
    echo ""
}

# Main function
main() {
    log_info "Starting Terraform backend setup"
    
    create_s3_bucket
    create_dynamodb_table
    update_terraform_backend
    display_info
    
    log_success "Terraform backend setup completed successfully!"
}

# Run main function
main "$@"