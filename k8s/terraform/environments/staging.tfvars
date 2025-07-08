# Staging Environment Configuration
environment = "staging"
aws_region  = "us-east-1"

# VPC Configuration
vpc_cidr        = "10.1.0.0/16"
private_subnets = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
public_subnets  = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]

# EKS Configuration
cluster_name    = "ai-agent-recruiter-staging"
cluster_version = "1.27"

# Node Group Configuration (balanced for staging)
node_group_instance_types = ["t3.medium"]
node_group_capacity_type  = "ON_DEMAND"
node_group_desired_size   = 2
node_group_max_size       = 4
node_group_min_size       = 1

# RDS Configuration (balanced for staging)
create_rds                = true
rds_instance_class        = "db.t3.small"
rds_allocated_storage     = 50
rds_max_allocated_storage = 200
rds_multi_az             = false

# ElastiCache Configuration
create_elasticache    = true
redis_node_type       = "cache.t3.small"
redis_num_cache_nodes = 1

# DNS Configuration
create_route53_zone     = false
domain_name             = "staging.ai-agent-recruiter.com"
create_acm_certificate  = false

# Security Configuration (moderate for staging)
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
cloudwatch_log_retention_days = 14
enable_container_insights     = true

# Cost Optimization
enable_spot_instances = false
rds_performance_insights_enabled = true