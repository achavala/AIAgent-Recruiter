# Production Environment Configuration
environment = "production"
aws_region  = "us-east-1"

# VPC Configuration
vpc_cidr        = "10.2.0.0/16"
private_subnets = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
public_subnets  = ["10.2.101.0/24", "10.2.102.0/24", "10.2.103.0/24"]

# EKS Configuration
cluster_name    = "ai-agent-recruiter-prod"
cluster_version = "1.27"

# Node Group Configuration (high availability for production)
node_group_instance_types = ["t3.large"]
node_group_capacity_type  = "ON_DEMAND"
node_group_desired_size   = 3
node_group_max_size       = 10
node_group_min_size       = 2

# RDS Configuration (high availability for production)
create_rds                = true
rds_instance_class        = "db.t3.medium"
rds_allocated_storage     = 100
rds_max_allocated_storage = 500
rds_multi_az             = true

# ElastiCache Configuration
create_elasticache    = true
redis_node_type       = "cache.t3.medium"
redis_num_cache_nodes = 2

# DNS Configuration
create_route53_zone     = true
domain_name             = "ai-agent-recruiter.com"
create_acm_certificate  = true

# Security Configuration (full security for production)
enable_waf           = true
enable_guardduty     = true
enable_config        = true
compliance_standard  = "SOC2"

# Network Configuration
enable_nat_gateway    = true
enable_vpn_gateway    = false
enable_dns_hostnames  = true
enable_dns_support    = true

# Logging Configuration
cloudwatch_log_retention_days = 30
enable_container_insights     = true

# Cost Optimization
enable_spot_instances = false
rds_performance_insights_enabled = true