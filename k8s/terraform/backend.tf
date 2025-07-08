# Terraform Backend Configuration
# This file defines the S3 backend for Terraform state management
# It will be updated by the setup-terraform-backend.sh script

terraform {
  backend "s3" {
    # These values will be updated by the CI/CD pipeline
    bucket         = "ai-agent-recruiter-terraform-state-development"
    key            = "development/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "ai-agent-recruiter-terraform-locks-development"
    encrypt        = true
  }
}