# Troubleshooting Guide for AI Agent Recruiter EKS Deployment

This guide helps you troubleshoot common issues you might encounter when deploying the AI Agent Recruiter application to EKS.

## Table of Contents

1. [General Troubleshooting Steps](#general-troubleshooting-steps)
2. [Infrastructure Issues](#infrastructure-issues)
3. [Application Deployment Issues](#application-deployment-issues)
4. [Runtime Issues](#runtime-issues)
5. [Performance Issues](#performance-issues)
6. [Networking Issues](#networking-issues)
7. [Security Issues](#security-issues)
8. [Monitoring and Logging Issues](#monitoring-and-logging-issues)

## General Troubleshooting Steps

### 1. Check Cluster Health

```bash
# Check cluster status
aws eks describe-cluster --name ai-agent-recruiter --region $AWS_REGION

# Check nodes
kubectl get nodes -o wide

# Check system pods
kubectl get pods -n kube-system

# Check cluster events
kubectl get events --sort-by=.metadata.creationTimestamp
```

### 2. Verify AWS Credentials and Permissions

```bash
# Check current AWS identity
aws sts get-caller-identity

# Test EKS access
aws eks list-clusters --region $AWS_REGION

# Check IAM permissions
aws iam get-user
aws iam list-attached-user-policies --user-name YOUR_USERNAME
```

### 3. Verify kubectl Configuration

```bash
# Check current context
kubectl config current-context

# Update kubeconfig
aws eks update-kubeconfig --region $AWS_REGION --name ai-agent-recruiter

# Test connection
kubectl cluster-info
```

## Infrastructure Issues

### Terraform Deployment Failures

#### Issue: "Resource already exists" errors
```bash
# Import existing resources
terraform import aws_s3_bucket.example bucket-name

# Or destroy and recreate
terraform destroy -target=aws_s3_bucket.example
terraform apply
```

#### Issue: VPC CIDR conflicts
```bash
# Check existing VPCs
aws ec2 describe-vpcs --region $AWS_REGION

# Update variables.tf with different CIDR
vpc_cidr = "10.1.0.0/16"
```

#### Issue: NAT Gateway creation timeout
```bash
# Check internet gateway
aws ec2 describe-internet-gateways --region $AWS_REGION

# Verify route tables
aws ec2 describe-route-tables --region $AWS_REGION
```

### EKS Cluster Issues

#### Issue: Cluster creation fails
```bash
# Check CloudFormation stacks
aws cloudformation list-stacks --region $AWS_REGION

# Check service quotas
aws service-quotas get-service-quota \
  --service-code eks \
  --quota-code L-1194D53C \
  --region $AWS_REGION
```

#### Issue: Node group creation fails
```bash
# Check instance limits
aws ec2 describe-account-attributes --region $AWS_REGION

# Check subnet capacity
aws ec2 describe-subnets --region $AWS_REGION
```

### RDS Issues

#### Issue: Database creation fails
```bash
# Check DB subnet groups
aws rds describe-db-subnet-groups --region $AWS_REGION

# Check security groups
aws ec2 describe-security-groups --region $AWS_REGION

# Check parameter groups
aws rds describe-db-parameter-groups --region $AWS_REGION
```

#### Issue: Connection timeouts
```bash
# Test connectivity from pod
kubectl run test-pod --image=postgres:15 --rm -it -- bash
# Inside pod:
psql -h your-rds-endpoint -U postgres -d aiagent_recruiter
```

## Application Deployment Issues

### Pod Startup Issues

#### Issue: Pods stuck in Pending state
```bash
# Check pod events
kubectl describe pod POD_NAME -n NAMESPACE

# Check node resources
kubectl describe nodes

# Check PVC status
kubectl get pvc -n NAMESPACE
```

#### Issue: ImagePullBackOff errors
```bash
# Check ECR repositories
aws ecr describe-repositories --region $AWS_REGION

# Check image existence
aws ecr list-images --repository-name ai-agent-recruiter-backend --region $AWS_REGION

# Check ECR permissions
aws ecr get-authorization-token --region $AWS_REGION

# Manually pull image to test
docker pull $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/ai-agent-recruiter-backend:latest
```

#### Issue: CrashLoopBackOff errors
```bash
# Check container logs
kubectl logs POD_NAME -c CONTAINER_NAME -n NAMESPACE --previous

# Check pod events
kubectl describe pod POD_NAME -n NAMESPACE

# Check resource limits
kubectl get pod POD_NAME -n NAMESPACE -o yaml | grep -A 10 resources
```

### Configuration Issues

#### Issue: ConfigMap not found
```bash
# Check ConfigMap exists
kubectl get configmap -n NAMESPACE

# Verify ConfigMap content
kubectl describe configmap ai-agent-recruiter-config -n NAMESPACE

# Check pod reference
kubectl get pod POD_NAME -n NAMESPACE -o yaml | grep -A 5 configMapKeyRef
```

#### Issue: Secret not found
```bash
# Check secrets
kubectl get secrets -n NAMESPACE

# Verify secret content (base64 encoded)
kubectl get secret ai-agent-recruiter-secrets -n NAMESPACE -o yaml

# Create missing secret
kubectl create secret generic ai-agent-recruiter-secrets \
  --from-literal=OPENAI_API_KEY=your_key \
  -n NAMESPACE
```

### Service and Ingress Issues

#### Issue: Service not accessible
```bash
# Check service endpoints
kubectl get endpoints -n NAMESPACE

# Check service selector
kubectl describe service SERVICE_NAME -n NAMESPACE

# Test service internally
kubectl run test-pod --image=curlimages/curl --rm -it -- sh
# Inside pod:
curl http://SERVICE_NAME.NAMESPACE.svc.cluster.local:PORT
```

#### Issue: Ingress not working
```bash
# Check ingress status
kubectl get ingress -n NAMESPACE

# Check ALB controller logs
kubectl logs -f deployment/aws-load-balancer-controller -n kube-system

# Check security groups
aws ec2 describe-security-groups --filters "Name=tag:kubernetes.io/cluster/ai-agent-recruiter,Values=owned"

# Check target groups
aws elbv2 describe-target-groups --region $AWS_REGION
```

## Runtime Issues

### Database Connection Issues

#### Issue: Cannot connect to PostgreSQL
```bash
# Check database status
aws rds describe-db-instances --region $AWS_REGION

# Test connection from pod
kubectl exec -it POD_NAME -n NAMESPACE -- bash
# Inside pod:
python -c "
import psycopg2
try:
    conn = psycopg2.connect(
        host='your-rds-endpoint',
        database='aiagent_recruiter',
        user='postgres',
        password='your_password'
    )
    print('Connection successful')
except Exception as e:
    print(f'Connection failed: {e}')
"
```

#### Issue: Database migrations fail
```bash
# Check migration status
kubectl exec -it BACKEND_POD -n NAMESPACE -- python -m alembic current

# Run migrations manually
kubectl exec -it BACKEND_POD -n NAMESPACE -- python -m alembic upgrade head

# Check database schema
kubectl exec -it BACKEND_POD -n NAMESPACE -- python -c "
from app.models import engine
from sqlalchemy import inspect
inspector = inspect(engine)
print(inspector.get_table_names())
"
```

### Application Performance Issues

#### Issue: High memory usage
```bash
# Check pod resource usage
kubectl top pods -n NAMESPACE

# Check memory limits
kubectl describe pod POD_NAME -n NAMESPACE | grep -A 5 Limits

# Increase memory limits in deployment
kubectl patch deployment DEPLOYMENT_NAME -n NAMESPACE -p '
{
  "spec": {
    "template": {
      "spec": {
        "containers": [
          {
            "name": "backend",
            "resources": {
              "limits": {
                "memory": "2Gi"
              }
            }
          }
        ]
      }
    }
  }
}'
```

#### Issue: High CPU usage
```bash
# Check CPU usage
kubectl top pods -n NAMESPACE

# Scale deployment
kubectl scale deployment DEPLOYMENT_NAME --replicas=5 -n NAMESPACE

# Check HPA status
kubectl get hpa -n NAMESPACE
kubectl describe hpa HPA_NAME -n NAMESPACE
```

### API Issues

#### Issue: 502 Bad Gateway errors
```bash
# Check backend pod status
kubectl get pods -n NAMESPACE -l component=backend

# Check backend logs
kubectl logs -f deployment/ai-agent-recruiter-backend -n NAMESPACE

# Check service endpoints
kubectl get endpoints ai-agent-recruiter-backend-service -n NAMESPACE

# Test backend health endpoint
kubectl exec -it POD_NAME -n NAMESPACE -- curl localhost:8000/health
```

#### Issue: CORS errors
```bash
# Check ingress annotations
kubectl describe ingress ai-agent-recruiter-ingress -n NAMESPACE

# Check ALB configuration
aws elbv2 describe-load-balancers --region $AWS_REGION

# Update CORS settings in ConfigMap
kubectl patch configmap ai-agent-recruiter-config -n NAMESPACE --type merge -p '
{
  "data": {
    "CORS_ORIGINS": "https://your-domain.com,https://www.your-domain.com"
  }
}'
```

## Performance Issues

### Slow Response Times

#### Issue: API responses are slow
```bash
# Check pod resource usage
kubectl top pods -n NAMESPACE

# Check database performance
aws rds describe-db-instances \
  --db-instance-identifier ai-agent-recruiter-db \
  --region $AWS_REGION \
  --query 'DBInstances[0].{Status:DBInstanceStatus,Class:DBInstanceClass,Engine:Engine}'

# Enable Performance Insights
aws rds modify-db-instance \
  --db-instance-identifier ai-agent-recruiter-db \
  --enable-performance-insights \
  --region $AWS_REGION
```

#### Issue: Frontend loading slowly
```bash
# Check CDN/caching
kubectl describe ingress ai-agent-recruiter-ingress -n NAMESPACE

# Check frontend build size
kubectl exec -it FRONTEND_POD -n NAMESPACE -- du -sh /usr/share/nginx/html

# Enable compression
kubectl annotate ingress ai-agent-recruiter-ingress -n NAMESPACE \
  nginx.ingress.kubernetes.io/gzip-enable=true
```

### Scaling Issues

#### Issue: HPA not scaling
```bash
# Check metrics server
kubectl get pods -n kube-system -l k8s-app=metrics-server

# Check HPA status
kubectl describe hpa ai-agent-recruiter-backend-hpa -n NAMESPACE

# Test metrics availability
kubectl top pods -n NAMESPACE

# Install metrics server if missing
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

## Networking Issues

### DNS Resolution Issues

#### Issue: Service discovery not working
```bash
# Test DNS resolution
kubectl run test-dns --image=busybox --rm -it -- nslookup ai-agent-recruiter-backend-service.NAMESPACE.svc.cluster.local

# Check CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Check CoreDNS logs
kubectl logs -f deployment/coredns -n kube-system
```

### Load Balancer Issues

#### Issue: ALB not created
```bash
# Check ALB controller
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Check ALB controller logs
kubectl logs -f deployment/aws-load-balancer-controller -n kube-system

# Check ingress class
kubectl get ingressclass

# Install ALB controller if missing
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=ai-agent-recruiter
```

## Security Issues

### RBAC Issues

#### Issue: Permission denied errors
```bash
# Check current permissions
kubectl auth can-i create pods --namespace=NAMESPACE

# Check service account
kubectl get serviceaccount ai-agent-recruiter-sa -n NAMESPACE

# Check role bindings
kubectl get rolebindings -n NAMESPACE

# Describe role
kubectl describe role ai-agent-recruiter-role -n NAMESPACE
```

### Secret Issues

#### Issue: Secret not accessible
```bash
# Check secret exists
kubectl get secret ai-agent-recruiter-secrets -n NAMESPACE

# Check secret data
kubectl describe secret ai-agent-recruiter-secrets -n NAMESPACE

# Test secret access from pod
kubectl exec -it POD_NAME -n NAMESPACE -- env | grep OPENAI_API_KEY
```

## Monitoring and Logging Issues

### Missing Logs

#### Issue: Logs not appearing in CloudWatch
```bash
# Check Fluent Bit
kubectl get pods -n amazon-cloudwatch -l app.kubernetes.io/name=fluent-bit

# Check Fluent Bit configuration
kubectl describe configmap fluent-bit-config -n amazon-cloudwatch

# Check CloudWatch log groups
aws logs describe-log-groups --region $AWS_REGION
```

### Metrics Issues

#### Issue: Prometheus metrics not available
```bash
# Check Prometheus
kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus

# Check metric endpoints
kubectl exec -it POD_NAME -n NAMESPACE -- curl localhost:9090/metrics

# Check service monitor
kubectl get servicemonitor -n NAMESPACE
```

## Emergency Procedures

### Complete Application Restart

```bash
# Restart all deployments
kubectl rollout restart deployment/ai-agent-recruiter-backend -n NAMESPACE
kubectl rollout restart deployment/ai-agent-recruiter-frontend -n NAMESPACE

# Wait for rollout to complete
kubectl rollout status deployment/ai-agent-recruiter-backend -n NAMESPACE
kubectl rollout status deployment/ai-agent-recruiter-frontend -n NAMESPACE
```

### Rollback Deployment

```bash
# Check rollout history
kubectl rollout history deployment/ai-agent-recruiter-backend -n NAMESPACE

# Rollback to previous version
kubectl rollout undo deployment/ai-agent-recruiter-backend -n NAMESPACE

# Rollback to specific revision
kubectl rollout undo deployment/ai-agent-recruiter-backend --to-revision=2 -n NAMESPACE
```

### Scale to Zero (Emergency Stop)

```bash
# Scale all deployments to zero
kubectl scale deployment ai-agent-recruiter-backend --replicas=0 -n NAMESPACE
kubectl scale deployment ai-agent-recruiter-frontend --replicas=0 -n NAMESPACE

# Scale back up
kubectl scale deployment ai-agent-recruiter-backend --replicas=3 -n NAMESPACE
kubectl scale deployment ai-agent-recruiter-frontend --replicas=3 -n NAMESPACE
```

## Getting Help

### Useful Commands for Support

```bash
# Collect cluster information
kubectl cluster-info dump > cluster-info.txt

# Export resource definitions
kubectl get all -n NAMESPACE -o yaml > namespace-resources.yaml

# Get events
kubectl get events --sort-by=.metadata.creationTimestamp -n NAMESPACE

# Get node information
kubectl describe nodes > nodes-info.txt
```

### Log Collection

```bash
# Collect pod logs
kubectl logs deployment/ai-agent-recruiter-backend -n NAMESPACE > backend.log
kubectl logs deployment/ai-agent-recruiter-frontend -n NAMESPACE > frontend.log

# Collect system logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller > alb-controller.log
kubectl logs -n kube-system deployment/coredns > coredns.log
```

### Performance Debugging

```bash
# Create debugging pod
kubectl run debug-pod --image=nicolaka/netshoot --rm -it -- bash

# Inside debugging pod, you can use tools like:
# - curl for HTTP testing
# - dig for DNS testing
# - tcpdump for network analysis
# - iostat for disk performance
```

For additional help, check the [AWS EKS Troubleshooting Guide](https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html) and [Kubernetes Troubleshooting Guide](https://kubernetes.io/docs/tasks/debug-application-cluster/troubleshooting/).