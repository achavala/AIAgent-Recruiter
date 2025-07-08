# Development Environment Configuration
environment = "development"
aws_region  = "us-east-1"

# VPC Configuration
vpc_cidr        = "10.0.0.0/16"
private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

# EKS Configuration
cluster_name    = "ai-agent-recruiter-dev"
cluster_version = "1.27"

# Node Group Configuration (minimal for development)
node_group_instance_types = ["t3.small"]
node_group_capacity_type  = "ON_DEMAND"
node_group_desired_size   = 1
node_group_max_size       = 3
node_group_min_size       = 1

# RDS Configuration (minimal for development)
create_rds                = true
rds_instance_class        = "db.t3.micro"
rds_allocated_storage     = 20
rds_max_allocated_storage = 50
rds_multi_az             = false

# ElastiCache Configuration
create_elasticache    = true
redis_node_type       = "cache.t3.micro"
redis_num_cache_nodes = 1

# DNS Configuration
create_route53_zone     = false
domain_name             = "dev.ai-agent-recruiter.com"
create_acm_certificate  = false

# Security Configuration (relaxed for development)
enable_waf           = false
enable_guardduty     = false
enable_config        = false
compliance_standard  = "SOC2"

# Network Configuration
enable_nat_gateway    = true
enable_vpn_gateway    = false
enable_dns_hostnames  = true
enable_dns_support    = true

# Logging Configuration
cloudwatch_log_retention_days = 7
enable_container_insights     = true

# Cost Optimization
enable_spot_instances = true
rds_performance_insights_enabled = false