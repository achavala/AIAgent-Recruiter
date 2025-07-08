# EKS Deployment Guide for AI Agent Recruiter

This guide provides step-by-step instructions for deploying the AI Agent Recruiter application to Amazon EKS (Elastic Kubernetes Service).

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Infrastructure Setup](#infrastructure-setup)
3. [Application Deployment](#application-deployment)
4. [Configuration](#configuration)
5. [Monitoring and Logging](#monitoring-and-logging)
6. [Scaling](#scaling)
7. [Security](#security)
8. [Backup and Recovery](#backup-and-recovery)
9. [Troubleshooting](#troubleshooting)
10. [Cost Optimization](#cost-optimization)

## Prerequisites

### Required Tools

Install the following tools on your local machine:

```bash
# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

# eksctl (optional but recommended)
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Docker
sudo apt-get update
sudo apt-get install docker.io
sudo usermod -aG docker $USER
```

### AWS Account Setup

1. **AWS Account**: Ensure you have an AWS account with appropriate permissions
2. **IAM User**: Create an IAM user with the following policies:
   - `AmazonEKSClusterPolicy`
   - `AmazonEKSWorkerNodePolicy`
   - `AmazonEKS_CNI_Policy`
   - `AmazonEC2ContainerRegistryFullAccess`
   - `AmazonRDSFullAccess`
   - `ElastiCacheFullAccess`
   - `AmazonS3FullAccess`
   - `AmazonRoute53FullAccess`
   - `AWSCertificateManagerFullAccess`

3. **Configure AWS CLI**:
```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, and region
```

### Domain and SSL (Optional)

If you want to use a custom domain:

1. **Domain**: Register a domain or have access to Route53 hosted zone
2. **SSL Certificate**: We'll create this automatically with ACM

## Infrastructure Setup

### Step 1: Clone the Repository

```bash
git clone https://github.com/achavala/AIAgent-Recruiter.git
cd AIAgent-Recruiter
```

### Step 2: Set Environment Variables

```bash
export AWS_REGION=us-east-1
export ENVIRONMENT=development  # or staging, production
export DOMAIN_NAME=your-domain.com  # optional
```

### Step 3: Deploy Infrastructure

```bash
# Make scripts executable
chmod +x k8s/scripts/*.sh

# Setup EKS cluster and infrastructure
./k8s/scripts/setup-cluster.sh --environment $ENVIRONMENT --region $AWS_REGION

# This will:
# 1. Create S3 bucket for Terraform state
# 2. Generate Terraform variables
# 3. Initialize and apply Terraform
# 4. Install Kubernetes addons
# 5. Display cluster information
```

### Step 4: Verify Infrastructure

```bash
# Configure kubectl
aws eks update-kubeconfig --region $AWS_REGION --name ai-agent-recruiter

# Check cluster status
kubectl get nodes
kubectl get pods -A

# Verify addons
kubectl get pods -n kube-system
```

## Application Deployment

### Step 1: Build and Push Docker Images

```bash
# Build and push images to ECR
./k8s/scripts/build-and-push.sh --environment $ENVIRONMENT --version v1.0.0

# This will:
# 1. Create ECR repositories
# 2. Build Docker images
# 3. Push to ECR
# 4. Scan for vulnerabilities
```

### Step 2: Configure Application Secrets

Create the necessary secrets in Kubernetes:

```bash
# Create secrets for the application
kubectl create secret generic ai-agent-recruiter-secrets \
  --from-literal=OPENAI_API_KEY=your_openai_api_key \
  --from-literal=EMAIL_USERNAME=your_email@example.com \
  --from-literal=EMAIL_PASSWORD=your_email_password \
  --from-literal=POSTGRES_PASSWORD=your_postgres_password \
  --from-literal=JWT_SECRET_KEY=$(openssl rand -base64 64) \
  --from-literal=ENCRYPTION_KEY=$(openssl rand -base64 32) \
  --namespace ai-agent-recruiter-${ENVIRONMENT}
```

### Step 3: Deploy Application

```bash
# Deploy application to Kubernetes
./k8s/scripts/deploy.sh --environment $ENVIRONMENT --version v1.0.0

# This will:
# 1. Deploy all Kubernetes manifests
# 2. Wait for deployments to be ready
# 3. Run database migrations
# 4. Display deployment status
```

### Step 4: Verify Deployment

```bash
# Check deployment status
kubectl get pods -n ai-agent-recruiter-${ENVIRONMENT}
kubectl get services -n ai-agent-recruiter-${ENVIRONMENT}
kubectl get ingress -n ai-agent-recruiter-${ENVIRONMENT}

# Check application logs
kubectl logs -f deployment/ai-agent-recruiter-backend -n ai-agent-recruiter-${ENVIRONMENT}
kubectl logs -f deployment/ai-agent-recruiter-frontend -n ai-agent-recruiter-${ENVIRONMENT}
```

## Configuration

### Environment-Specific Configuration

The deployment supports three environments with different configurations:

#### Development
- **Namespace**: `ai-agent-recruiter-dev`
- **Replicas**: Backend: 1, Frontend: 1
- **Resources**: Minimal (optimized for cost)
- **Database**: In-cluster PostgreSQL or SQLite
- **Domain**: `dev.ai-agent-recruiter.com`

#### Staging
- **Namespace**: `ai-agent-recruiter-staging`
- **Replicas**: Backend: 2, Frontend: 2
- **Resources**: Medium (balanced)
- **Database**: RDS PostgreSQL
- **Domain**: `staging.ai-agent-recruiter.com`

#### Production
- **Namespace**: `ai-agent-recruiter`
- **Replicas**: Backend: 3, Frontend: 3
- **Resources**: High (performance optimized)
- **Database**: RDS PostgreSQL with Multi-AZ
- **Domain**: `ai-agent-recruiter.com`

### ConfigMap Configuration

Update the ConfigMap in `k8s/manifests/configmap.yaml` for environment-specific settings:

```yaml
data:
  # Adjust these values based on your needs
  SCRAPING_INTERVAL_HOURS: "1"
  JOB_RELEVANCE_THRESHOLD: "0.7"
  MAX_WORKERS: "4"
  LOG_LEVEL: "INFO"
```

### Secret Management

Secrets are managed through Kubernetes secrets and AWS Secrets Manager:

1. **Kubernetes Secrets**: For application secrets
2. **AWS Secrets Manager**: For infrastructure secrets (optional)
3. **AWS Systems Manager Parameter Store**: For configuration parameters

## Monitoring and Logging

### Prometheus and Grafana Setup

```bash
# Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.adminPassword=admin123

# Access Grafana
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring
# Open http://localhost:3000 (admin/admin123)
```

### CloudWatch Integration

The deployment automatically configures CloudWatch integration:

1. **Container Insights**: Enabled for the EKS cluster
2. **Log Groups**: Automatically created for application logs
3. **Metrics**: Custom metrics from the application

### Log Aggregation

```bash
# Install Fluent Bit for log forwarding
helm repo add fluent https://fluent.github.io/helm-charts
helm install fluent-bit fluent/fluent-bit \
  --namespace logging \
  --create-namespace \
  --set cloudWatch.enabled=true \
  --set cloudWatch.region=$AWS_REGION
```

## Scaling

### Horizontal Pod Autoscaling (HPA)

HPA is automatically configured and will scale pods based on CPU and memory usage:

```bash
# Check HPA status
kubectl get hpa -n ai-agent-recruiter-${ENVIRONMENT}

# View HPA details
kubectl describe hpa ai-agent-recruiter-backend-hpa -n ai-agent-recruiter-${ENVIRONMENT}
```

### Cluster Autoscaling

The Cluster Autoscaler is automatically installed and will scale nodes based on demand:

```bash
# Check cluster autoscaler logs
kubectl logs -f deployment/cluster-autoscaler -n kube-system
```

### Manual Scaling

```bash
# Scale backend deployment
kubectl scale deployment ai-agent-recruiter-backend --replicas=5 -n ai-agent-recruiter-${ENVIRONMENT}

# Scale frontend deployment
kubectl scale deployment ai-agent-recruiter-frontend --replicas=3 -n ai-agent-recruiter-${ENVIRONMENT}
```

## Security

### Network Policies

Network policies are automatically applied to restrict traffic between pods:

```bash
# View network policies
kubectl get networkpolicies -n ai-agent-recruiter-${ENVIRONMENT}
```

### Pod Security Standards

Pod Security Standards are enforced through:

1. **Pod Security Policy**: Restricts privileged containers
2. **Security Context**: Runs containers as non-root
3. **Read-only Root Filesystem**: Prevents runtime modifications

### RBAC

Role-Based Access Control is configured with minimal permissions:

```bash
# View RBAC configuration
kubectl get roles,rolebindings -n ai-agent-recruiter-${ENVIRONMENT}
```

### Secrets Encryption

- **etcd Encryption**: Enabled for secrets at rest
- **In-transit Encryption**: TLS for all communications
- **Secrets Management**: Using Kubernetes secrets and AWS Secrets Manager

## Backup and Recovery

### Database Backup

For RDS PostgreSQL:

1. **Automated Backups**: Enabled with 7-day retention
2. **Manual Snapshots**: Create before major deployments
3. **Cross-Region Backup**: Optional for production

```bash
# Create manual RDS snapshot
aws rds create-db-snapshot \
  --db-snapshot-identifier ai-agent-recruiter-manual-$(date +%Y%m%d%H%M) \
  --db-instance-identifier ai-agent-recruiter-db
```

### Application Data Backup

```bash
# Backup application data to S3
kubectl exec -n ai-agent-recruiter-${ENVIRONMENT} deployment/ai-agent-recruiter-backend -- \
  python scripts/backup_data.py --output-s3 s3://ai-agent-recruiter-backups/
```

### Disaster Recovery

1. **Multi-AZ Deployment**: Configured for production
2. **Cross-Region Replication**: For critical data
3. **Infrastructure as Code**: Complete environment recreation possible

## Troubleshooting

### Common Issues

#### 1. Pods Stuck in Pending State

```bash
# Check node capacity
kubectl describe nodes

# Check pod events
kubectl describe pod <pod-name> -n ai-agent-recruiter-${ENVIRONMENT}

# Check resource quotas
kubectl get resourcequota -n ai-agent-recruiter-${ENVIRONMENT}
```

#### 2. Image Pull Errors

```bash
# Check ECR permissions
aws ecr describe-repositories --region $AWS_REGION

# Check if image exists
aws ecr describe-images --repository-name ai-agent-recruiter-backend --region $AWS_REGION

# Update kubeconfig
aws eks update-kubeconfig --region $AWS_REGION --name ai-agent-recruiter
```

#### 3. Database Connection Issues

```bash
# Check database status
aws rds describe-db-instances --region $AWS_REGION

# Test connectivity from pod
kubectl exec -it <pod-name> -n ai-agent-recruiter-${ENVIRONMENT} -- \
  python -c "import psycopg2; print('Connection test')"
```

#### 4. Ingress Issues

```bash
# Check ALB controller
kubectl logs -f deployment/aws-load-balancer-controller -n kube-system

# Check ingress events
kubectl describe ingress ai-agent-recruiter-ingress -n ai-agent-recruiter-${ENVIRONMENT}

# Check security groups
aws ec2 describe-security-groups --region $AWS_REGION
```

### Debug Commands

```bash
# Get all resources in namespace
kubectl get all -n ai-agent-recruiter-${ENVIRONMENT}

# Check pod logs
kubectl logs <pod-name> -n ai-agent-recruiter-${ENVIRONMENT} --previous

# Execute into pod
kubectl exec -it <pod-name> -n ai-agent-recruiter-${ENVIRONMENT} -- /bin/bash

# Port forward for debugging
kubectl port-forward svc/ai-agent-recruiter-backend-service 8000:8000 -n ai-agent-recruiter-${ENVIRONMENT}
```

### Performance Monitoring

```bash
# Check resource usage
kubectl top nodes
kubectl top pods -n ai-agent-recruiter-${ENVIRONMENT}

# View metrics
kubectl get --raw /metrics | grep ai_agent_recruiter
```

## Cost Optimization

### Development Environment

1. **Single NAT Gateway**: Reduces NAT costs
2. **Spot Instances**: Use for development workloads
3. **Smaller Instance Types**: t3.medium or smaller
4. **Auto-scaling**: Scale down during off-hours

### Production Environment

1. **Reserved Instances**: For predictable workloads
2. **EBS GP3**: More cost-effective than GP2
3. **S3 Lifecycle Policies**: Move old logs to cheaper storage
4. **CloudWatch Log Retention**: Set appropriate retention periods

### Monitoring Costs

```bash
# Check AWS Cost Explorer
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```

### Cost Optimization Scripts

```bash
# Stop development environment after hours
./k8s/scripts/schedule-downscale.sh --environment development --schedule "0 18 * * 1-5"

# Auto-scale down during weekends
kubectl patch deployment ai-agent-recruiter-backend -n ai-agent-recruiter-dev \
  -p '{"spec":{"replicas":0}}'
```

## Maintenance

### Regular Maintenance Tasks

1. **Update Node Groups**: Monthly updates for security patches
2. **Update Kubernetes Version**: Quarterly updates
3. **Update Application Images**: With each release
4. **Review and Rotate Secrets**: Quarterly
5. **Clean Up Old Resources**: Monthly cleanup

### Update Procedures

```bash
# Update Kubernetes version
aws eks update-cluster-version --name ai-agent-recruiter --kubernetes-version 1.28

# Update node groups
aws eks update-nodegroup-version \
  --cluster-name ai-agent-recruiter \
  --nodegroup-name main

# Update application
./k8s/scripts/deploy.sh --environment $ENVIRONMENT --version v1.1.0
```

### Health Checks

```bash
# Automated health check script
./k8s/scripts/health-check.sh --environment $ENVIRONMENT

# Manual health checks
kubectl get nodes
kubectl get pods -A
aws eks describe-cluster --name ai-agent-recruiter --region $AWS_REGION
```

## Next Steps

1. **Set up monitoring dashboards** in Grafana
2. **Configure alerting** for critical metrics
3. **Implement backup automation**
4. **Set up development workflows**
5. **Configure CI/CD pipelines**
6. **Plan disaster recovery procedures**

For additional support and advanced configurations, refer to the [Troubleshooting Guide](./TROUBLESHOOTING.md) and [Advanced Configuration](./ADVANCED_CONFIG.md) documents.