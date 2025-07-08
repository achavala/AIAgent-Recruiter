# AI Agent Recruiter - EKS Deployment

This directory contains comprehensive Amazon EKS deployment configuration for the AI Agent Recruiter application.

## 🏗️ Architecture Overview

The deployment provides a production-ready, scalable, and secure Kubernetes environment with:

- **Multi-environment support** (development, staging, production)
- **High availability** with multi-AZ deployment
- **Auto-scaling** based on metrics
- **Security hardening** with RBAC and network policies
- **Monitoring and logging** integration
- **Disaster recovery** capabilities
- **Cost optimization** features

## 📁 Directory Structure

```
k8s/
├── manifests/              # Kubernetes manifests
│   ├── namespace.yaml       # Multi-environment namespaces
│   ├── configmap.yaml      # Environment configuration
│   ├── secret.yaml         # Secure secrets template
│   ├── backend-deployment.yaml   # FastAPI backend
│   ├── backend-service.yaml      # Backend service
│   ├── frontend-deployment.yaml  # React frontend
│   ├── frontend-service.yaml     # Frontend service
│   ├── ingress.yaml        # ALB ingress with SSL
│   ├── pvc.yaml           # Storage configuration
│   ├── rbac.yaml          # Security and permissions
│   └── hpa.yaml           # Auto-scaling rules
├── terraform/             # Infrastructure as Code
│   ├── main.tf            # Complete AWS infrastructure
│   ├── variables.tf       # Configuration variables
│   └── outputs.tf         # Useful outputs
├── scripts/               # Automation scripts
│   ├── setup-cluster.sh   # Complete cluster setup
│   ├── build-and-push.sh  # Docker build and ECR push
│   └── deploy.sh          # Application deployment
├── DEPLOYMENT_GUIDE.md    # Step-by-step deployment guide
├── TROUBLESHOOTING.md     # Troubleshooting guide
├── ADVANCED_CONFIG.md     # Advanced configuration options
└── README.md             # This file
```

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured with appropriate permissions
- Docker, kubectl, Terraform, and Helm installed
- Domain name (optional, for custom domains)

### 1. Setup Infrastructure

```bash
# Clone repository
git clone https://github.com/achavala/AIAgent-Recruiter.git
cd AIAgent-Recruiter

# Set environment variables
export AWS_REGION=us-east-1
export ENVIRONMENT=production  # or staging, development

# Setup EKS cluster and infrastructure
./k8s/scripts/setup-cluster.sh --environment $ENVIRONMENT --region $AWS_REGION
```

### 2. Deploy Application

```bash
# Build and push Docker images
./k8s/scripts/build-and-push.sh --environment $ENVIRONMENT

# Configure secrets
kubectl create secret generic ai-agent-recruiter-secrets \
  --from-literal=OPENAI_API_KEY=your_openai_api_key \
  --from-literal=EMAIL_USERNAME=your_email@example.com \
  --from-literal=EMAIL_PASSWORD=your_email_password \
  --from-literal=POSTGRES_PASSWORD=your_postgres_password \
  --from-literal=JWT_SECRET_KEY=$(openssl rand -base64 64) \
  --from-literal=ENCRYPTION_KEY=$(openssl rand -base64 32) \
  --namespace ai-agent-recruiter-${ENVIRONMENT}

# Deploy application
./k8s/scripts/deploy.sh --environment $ENVIRONMENT
```

### 3. Verify Deployment

```bash
# Check deployment status
kubectl get pods -n ai-agent-recruiter-${ENVIRONMENT}
kubectl get services -n ai-agent-recruiter-${ENVIRONMENT}
kubectl get ingress -n ai-agent-recruiter-${ENVIRONMENT}

# Check application logs
kubectl logs -f deployment/ai-agent-recruiter-backend -n ai-agent-recruiter-${ENVIRONMENT}
```

## 🌍 Environment Configuration

### Development
- **Namespace**: `ai-agent-recruiter-dev`
- **Replicas**: Backend: 1, Frontend: 1
- **Resources**: Minimal for cost optimization
- **Database**: In-cluster PostgreSQL or SQLite
- **Domain**: `dev.ai-agent-recruiter.com`

### Staging
- **Namespace**: `ai-agent-recruiter-staging`
- **Replicas**: Backend: 2, Frontend: 2
- **Resources**: Balanced configuration
- **Database**: RDS PostgreSQL
- **Domain**: `staging.ai-agent-recruiter.com`

### Production
- **Namespace**: `ai-agent-recruiter`
- **Replicas**: Backend: 3, Frontend: 3
- **Resources**: High performance configuration
- **Database**: RDS PostgreSQL with Multi-AZ
- **Domain**: `ai-agent-recruiter.com`

## 🏗️ Infrastructure Components

### AWS Resources Created

- **EKS Cluster**: Managed Kubernetes cluster with managed node groups
- **VPC**: Multi-AZ VPC with public and private subnets
- **RDS**: PostgreSQL database with automated backups
- **ElastiCache**: Redis cluster for caching
- **ALB**: Application Load Balancer with SSL termination
- **ECR**: Container registry for Docker images
- **S3**: Buckets for assets and logs
- **IAM**: Roles and policies with minimal permissions
- **Route53**: DNS management (optional)
- **ACM**: SSL certificates (optional)
- **WAF**: Web Application Firewall for security

### Kubernetes Resources

- **Deployments**: Backend (FastAPI) and Frontend (React)
- **Services**: Internal load balancing
- **Ingress**: External access with SSL/TLS
- **ConfigMaps**: Environment-specific configuration
- **Secrets**: Secure storage for sensitive data
- **PVCs**: Persistent storage for database
- **HPA**: Horizontal Pod Autoscaler
- **RBAC**: Role-based access control
- **Network Policies**: Traffic restrictions

## 🔧 Key Features

### Security
- **Pod Security Standards**: Enforced security policies
- **Network Policies**: Traffic isolation
- **RBAC**: Minimal permissions
- **Secrets Management**: Encrypted storage
- **WAF Protection**: Application-level security
- **SSL/TLS**: End-to-end encryption

### High Availability
- **Multi-AZ**: Deployed across availability zones
- **Load Balancing**: Automatic traffic distribution
- **Health Checks**: Automated failure detection
- **Rolling Updates**: Zero-downtime deployments
- **Database Backups**: Automated and cross-region

### Scalability
- **Horizontal Pod Autoscaler**: CPU/memory-based scaling
- **Cluster Autoscaler**: Node scaling
- **Vertical Pod Autoscaler**: Right-sizing resources
- **Load Balancer**: Handles traffic spikes

### Monitoring
- **Prometheus**: Metrics collection
- **Grafana**: Visualization dashboards
- **CloudWatch**: AWS-native monitoring
- **Logging**: Centralized log aggregation
- **Alerting**: Proactive issue detection

### Cost Optimization
- **Spot Instances**: Reduced compute costs
- **Auto-scaling**: Pay for what you use
- **Resource Right-sizing**: Optimal resource allocation
- **Storage Optimization**: Efficient storage usage

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow

The included CI/CD pipeline provides:

- **Automated Testing**: Backend and frontend tests
- **Security Scanning**: Vulnerability detection
- **Docker Build**: Multi-platform image builds
- **Deployment**: Environment-specific deployments
- **Rollback**: Automatic rollback on failures
- **Notifications**: Slack integration

### Deployment Strategy

- **Rolling Updates**: Zero-downtime deployments
- **Blue-Green**: Optional for critical deployments
- **Canary**: Gradual rollout support
- **Feature Flags**: A/B testing capabilities

## 📊 Monitoring and Observability

### Metrics Collected

- **Application Metrics**: Request rate, response time, errors
- **Infrastructure Metrics**: CPU, memory, disk, network
- **Business Metrics**: Jobs scraped, AI analysis performance
- **Security Metrics**: Authentication, authorization events

### Dashboards Available

- **Application Dashboard**: Application-specific metrics
- **Infrastructure Dashboard**: Cluster and node metrics
- **Database Dashboard**: RDS performance metrics
- **Cost Dashboard**: Resource utilization and costs

## 🔧 Maintenance

### Regular Tasks

- **Security Updates**: Monthly node group updates
- **Kubernetes Updates**: Quarterly version upgrades
- **Database Maintenance**: Automated backup verification
- **Secret Rotation**: Quarterly secret updates
- **Cost Review**: Monthly cost optimization

### Backup Strategy

- **Database**: Daily automated backups with 7-day retention
- **Application Data**: Continuous backup to S3
- **Configuration**: Version-controlled in Git
- **Disaster Recovery**: Cross-region replication

## 📚 Documentation

- **[Deployment Guide](DEPLOYMENT_GUIDE.md)**: Complete deployment instructions
- **[Troubleshooting Guide](TROUBLESHOOTING.md)**: Common issues and solutions
- **[Advanced Configuration](ADVANCED_CONFIG.md)**: Advanced setup options

## 🛠️ Customization

### Environment Variables

Customize the deployment by modifying:

- `k8s/manifests/configmap.yaml`: Application configuration
- `k8s/terraform/variables.tf`: Infrastructure settings
- `.github/workflows/deploy.yml`: CI/CD pipeline

### Resource Scaling

Adjust resources based on your needs:

```bash
# Scale deployments
kubectl scale deployment ai-agent-recruiter-backend --replicas=5 -n ai-agent-recruiter

# Update resource limits
kubectl patch deployment ai-agent-recruiter-backend -n ai-agent-recruiter -p '
{
  "spec": {
    "template": {
      "spec": {
        "containers": [
          {
            "name": "backend",
            "resources": {
              "limits": {
                "memory": "2Gi",
                "cpu": "1000m"
              }
            }
          }
        ]
      }
    }
  }
}'
```

## 🔐 Security Considerations

### Production Hardening

1. **Enable Pod Security Standards**
2. **Configure Network Policies**
3. **Use AWS Secrets Manager**
4. **Enable GuardDuty and Security Hub**
5. **Regular Security Scans**
6. **Implement WAF Rules**
7. **Enable CloudTrail Logging**

### Compliance

The deployment supports:

- **SOC 2**: Security and availability controls
- **GDPR**: Data protection and privacy
- **HIPAA**: Healthcare data security (with additional configuration)
- **PCI DSS**: Payment card industry standards

## 💰 Cost Estimation

### Development Environment
- **EKS Cluster**: ~$73/month
- **EC2 Instances**: ~$50-100/month
- **RDS**: ~$15-30/month
- **Total**: ~$140-200/month

### Production Environment
- **EKS Cluster**: ~$73/month
- **EC2 Instances**: ~$200-500/month
- **RDS Multi-AZ**: ~$100-200/month
- **Load Balancer**: ~$22/month
- **Total**: ~$400-800/month

### Cost Optimization Tips

1. Use Spot Instances for development
2. Enable Cluster Autoscaler
3. Use gp3 storage instead of gp2
4. Consider Reserved Instances for production
5. Monitor and optimize data transfer costs

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📞 Support

For issues and questions:

1. Check the [Troubleshooting Guide](TROUBLESHOOTING.md)
2. Review [GitHub Issues](https://github.com/achavala/AIAgent-Recruiter/issues)
3. Create a new issue with detailed information

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

---

**Note**: This deployment configuration provides enterprise-grade features suitable for production workloads. Always review and customize the configuration based on your specific security, compliance, and operational requirements.