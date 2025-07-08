# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "nat_gateway_ids" {
  description = "List of IDs of the NAT Gateways"
  value       = module.vpc.nat_gateways
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

# EKS Outputs
output "cluster_id" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = module.eks.cluster_oidc_issuer_url
}

output "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  value       = module.eks.cluster_version
}

output "cluster_platform_version" {
  description = "Platform version for the EKS cluster"
  value       = module.eks.cluster_platform_version
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

# EKS Node Group Outputs
output "node_groups" {
  description = "EKS node group outputs"
  value       = module.eks.eks_managed_node_groups
}

output "node_security_group_id" {
  description = "ID of the EKS node shared security group"
  value       = module.eks.node_security_group_id
}

# RDS Outputs
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = var.create_rds ? aws_db_instance.main[0].endpoint : null
}

output "rds_port" {
  description = "RDS instance port"
  value       = var.create_rds ? aws_db_instance.main[0].port : null
}

output "rds_instance_id" {
  description = "RDS instance ID"
  value       = var.create_rds ? aws_db_instance.main[0].id : null
}

output "rds_instance_arn" {
  description = "RDS instance ARN"
  value       = var.create_rds ? aws_db_instance.main[0].arn : null
}

output "rds_db_name" {
  description = "RDS database name"
  value       = var.create_rds ? aws_db_instance.main[0].db_name : null
}

output "rds_username" {
  description = "RDS master username"
  value       = var.create_rds ? aws_db_instance.main[0].username : null
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}

# ElastiCache Outputs
output "elasticache_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = var.create_elasticache ? aws_elasticache_replication_group.main[0].configuration_endpoint_address : null
}

output "elasticache_port" {
  description = "ElastiCache Redis port"
  value       = var.create_elasticache ? aws_elasticache_replication_group.main[0].port : null
}

output "elasticache_replication_group_id" {
  description = "ElastiCache replication group ID"
  value       = var.create_elasticache ? aws_elasticache_replication_group.main[0].replication_group_id : null
}

output "elasticache_security_group_id" {
  description = "ElastiCache security group ID"
  value       = aws_security_group.elasticache.id
}

# S3 Outputs
output "s3_bucket_assets" {
  description = "S3 bucket for assets"
  value       = aws_s3_bucket.assets.bucket
}

output "s3_bucket_assets_arn" {
  description = "S3 bucket ARN for assets"
  value       = aws_s3_bucket.assets.arn
}

output "s3_bucket_alb_logs" {
  description = "S3 bucket for ALB logs"
  value       = aws_s3_bucket.alb_logs.bucket
}

output "s3_bucket_alb_logs_arn" {
  description = "S3 bucket ARN for ALB logs"
  value       = aws_s3_bucket.alb_logs.arn
}

# IAM Outputs
output "eks_service_account_role_arn" {
  description = "ARN of the EKS service account IAM role"
  value       = aws_iam_role.eks_service_account.arn
}

output "eks_service_account_role_name" {
  description = "Name of the EKS service account IAM role"
  value       = aws_iam_role.eks_service_account.name
}

output "rds_monitoring_role_arn" {
  description = "ARN of the RDS monitoring IAM role"
  value       = aws_iam_role.rds_monitoring.arn
}

# Secrets Manager Outputs
output "secrets_manager_secret_arn" {
  description = "ARN of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.app_secrets.arn
}

output "secrets_manager_secret_name" {
  description = "Name of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.app_secrets.name
}

# Route53 Outputs
output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = var.create_route53_zone ? aws_route53_zone.main[0].zone_id : null
}

output "route53_zone_name" {
  description = "Route53 hosted zone name"
  value       = var.create_route53_zone ? aws_route53_zone.main[0].name : null
}

output "route53_name_servers" {
  description = "Route53 name servers"
  value       = var.create_route53_zone ? aws_route53_zone.main[0].name_servers : null
}

# ACM Certificate Outputs
output "acm_certificate_arn" {
  description = "ACM certificate ARN"
  value       = var.create_acm_certificate ? aws_acm_certificate.main[0].arn : null
}

output "acm_certificate_status" {
  description = "ACM certificate status"
  value       = var.create_acm_certificate ? aws_acm_certificate.main[0].status : null
}

# WAF Outputs
output "waf_web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = var.create_waf ? aws_wafv2_web_acl.main[0].arn : null
}

output "waf_web_acl_id" {
  description = "WAF Web ACL ID"
  value       = var.create_waf ? aws_wafv2_web_acl.main[0].id : null
}

# General Outputs
output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "project_name" {
  description = "Project name"
  value       = local.name
}

output "tags" {
  description = "Common tags applied to resources"
  value       = local.tags
}

# Kubectl Configuration
output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_name}"
}

# Connection Information
output "connection_info" {
  description = "Connection information for the infrastructure"
  value = {
    cluster_name     = module.eks.cluster_name
    cluster_endpoint = module.eks.cluster_endpoint
    database_endpoint = var.create_rds ? aws_db_instance.main[0].endpoint : null
    cache_endpoint   = var.create_elasticache ? aws_elasticache_replication_group.main[0].configuration_endpoint_address : null
    s3_assets_bucket = aws_s3_bucket.assets.bucket
    region          = var.aws_region
    environment     = var.environment
  }
}

# Kubernetes Deployment Commands
output "deployment_commands" {
  description = "Commands to deploy the application"
  value = {
    configure_kubectl = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_name}"
    deploy_manifests  = "kubectl apply -f k8s/manifests/"
    check_pods       = "kubectl get pods -n ai-agent-recruiter"
    check_services   = "kubectl get services -n ai-agent-recruiter"
    check_ingress    = "kubectl get ingress -n ai-agent-recruiter"
  }
}

# Monitoring URLs
output "monitoring_urls" {
  description = "URLs for monitoring and observability"
  value = {
    cloudwatch_logs      = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#logsV2:log-groups"
    cloudwatch_metrics   = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#metricsV2:graph=~()"
    eks_cluster_console  = "https://console.aws.amazon.com/eks/home?region=${var.aws_region}#/clusters/${module.eks.cluster_name}"
    rds_console         = var.create_rds ? "https://console.aws.amazon.com/rds/home?region=${var.aws_region}#database:id=${aws_db_instance.main[0].id}" : null
  }
}

# Security Information
output "security_info" {
  description = "Security-related information"
  value = {
    eks_cluster_security_group_id = module.eks.cluster_security_group_id
    rds_security_group_id        = aws_security_group.rds.id
    elasticache_security_group_id = aws_security_group.elasticache.id
    waf_web_acl_arn             = var.create_waf ? aws_wafv2_web_acl.main[0].arn : null
    secrets_manager_secret_arn   = aws_secretsmanager_secret.app_secrets.arn
  }
}

# Backup Information
output "backup_info" {
  description = "Backup-related information"
  value = {
    rds_backup_retention_period = var.create_rds ? aws_db_instance.main[0].backup_retention_period : null
    rds_backup_window          = var.create_rds ? aws_db_instance.main[0].backup_window : null
    s3_alb_logs_bucket         = aws_s3_bucket.alb_logs.bucket
  }
}

# Cost Information
output "cost_info" {
  description = "Cost-related information"
  value = {
    estimated_monthly_cost = {
      eks_cluster          = "~$73/month (cluster management)"
      node_group_instances = "Depends on instance types and count"
      rds_instance        = var.create_rds ? "Depends on instance class: ${var.rds_instance_class}" : null
      elasticache         = var.create_elasticache ? "Depends on node type: ${var.redis_node_type}" : null
      nat_gateways        = var.enable_nat_gateway ? "~$45/month per NAT Gateway" : null
      load_balancers      = "~$22/month per ALB"
      data_transfer       = "Variable based on usage"
    }
    cost_optimization_tips = [
      "Use Spot instances for development and testing",
      "Enable cluster autoscaler to scale down during low usage",
      "Use gp3 storage instead of gp2 for cost savings",
      "Consider Reserved Instances for production workloads",
      "Monitor and optimize data transfer costs"
    ]
  }
}