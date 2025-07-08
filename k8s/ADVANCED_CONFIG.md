# Advanced Configuration Guide for AI Agent Recruiter EKS

This guide covers advanced configuration options and best practices for running the AI Agent Recruiter application on EKS.

## Table of Contents

1. [Environment Configuration](#environment-configuration)
2. [Security Hardening](#security-hardening)
3. [Performance Optimization](#performance-optimization)
4. [High Availability Setup](#high-availability-setup)
5. [Monitoring and Observability](#monitoring-and-observability)
6. [Backup and Disaster Recovery](#backup-and-disaster-recovery)
7. [Cost Optimization](#cost-optimization)
8. [Advanced Networking](#advanced-networking)
9. [CI/CD Enhancements](#cicd-enhancements)
10. [Compliance and Governance](#compliance-and-governance)

## Environment Configuration

### Environment Variables

Comprehensive environment configuration for different deployment scenarios:

#### Development Environment
```yaml
# k8s/manifests/configmap-dev.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ai-agent-recruiter-config
  namespace: ai-agent-recruiter-dev
data:
  # Development-specific settings
  LOG_LEVEL: "DEBUG"
  DEBUG: "true"
  CORS_ORIGINS: "*"
  RATE_LIMIT_PER_MINUTE: "1000"
  MAX_WORKERS: "1"
  CACHE_TTL: "300"
  
  # Development database
  DATABASE_POOL_SIZE: "5"
  DATABASE_MAX_OVERFLOW: "10"
  
  # AI Settings for development
  AI_MODEL: "gpt-3.5-turbo"
  AI_TIMEOUT: "30"
  AI_MAX_RETRIES: "3"
```

#### Production Environment
```yaml
# k8s/manifests/configmap-prod.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ai-agent-recruiter-config
  namespace: ai-agent-recruiter
data:
  # Production settings
  LOG_LEVEL: "INFO"
  DEBUG: "false"
  CORS_ORIGINS: "https://ai-agent-recruiter.com,https://www.ai-agent-recruiter.com"
  RATE_LIMIT_PER_MINUTE: "100"
  MAX_WORKERS: "4"
  CACHE_TTL: "3600"
  
  # Production database
  DATABASE_POOL_SIZE: "20"
  DATABASE_MAX_OVERFLOW: "30"
  DATABASE_POOL_TIMEOUT: "30"
  DATABASE_POOL_RECYCLE: "3600"
  
  # AI Settings for production
  AI_MODEL: "gpt-4"
  AI_TIMEOUT: "60"
  AI_MAX_RETRIES: "5"
  AI_RATE_LIMIT: "50"
  
  # Monitoring
  METRICS_ENABLED: "true"
  HEALTH_CHECK_INTERVAL: "30"
  
  # Security
  SESSION_TIMEOUT: "3600"
  SECURE_COOKIES: "true"
  CSRF_PROTECTION: "true"
```

### Feature Flags

Implement feature flags for gradual rollouts:

```yaml
# k8s/manifests/configmap-features.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ai-agent-recruiter-features
  namespace: ai-agent-recruiter
data:
  # Feature flags
  ENABLE_NEW_AI_MODEL: "false"
  ENABLE_ADVANCED_FILTERING: "true"
  ENABLE_REAL_TIME_NOTIFICATIONS: "true"
  ENABLE_ANALYTICS_DASHBOARD: "false"
  ENABLE_MOBILE_API: "true"
  
  # Percentage rollouts
  NEW_UI_ROLLOUT_PERCENTAGE: "10"
  ENHANCED_SEARCH_PERCENTAGE: "50"
```

## Security Hardening

### Pod Security Standards

Enhanced pod security configuration:

```yaml
# k8s/manifests/pod-security-policy.yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: ai-agent-recruiter-restricted
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    - 'persistentVolumeClaim'
  hostNetwork: false
  hostIPC: false
  hostPID: false
  runAsUser:
    rule: 'MustRunAsNonRoot'
  supplementalGroups:
    rule: 'MustRunAs'
    ranges:
      - min: 1
        max: 65535
  fsGroup:
    rule: 'MustRunAs'
    ranges:
      - min: 1
        max: 65535
  readOnlyRootFilesystem: true
  seLinux:
    rule: 'RunAsAny'
```

### Network Policies

Comprehensive network security:

```yaml
# k8s/manifests/network-policy-strict.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ai-agent-recruiter-strict
  namespace: ai-agent-recruiter
spec:
  podSelector:
    matchLabels:
      app: ai-agent-recruiter
  policyTypes:
  - Ingress
  - Egress
  ingress:
  # Allow ingress only from ALB
  - from:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: TCP
      port: 8000
    - protocol: TCP
      port: 3000
  # Allow metrics scraping
  - from:
    - namespaceSelector:
        matchLabels:
          name: monitoring
    ports:
    - protocol: TCP
      port: 9090
  egress:
  # Allow DNS
  - to: []
    ports:
    - protocol: UDP
      port: 53
  # Allow HTTPS for external APIs
  - to: []
    ports:
    - protocol: TCP
      port: 443
  # Allow database access
  - to:
    - podSelector:
        matchLabels:
          component: database
    ports:
    - protocol: TCP
      port: 5432
  # Allow cache access
  - to:
    - podSelector:
        matchLabels:
          component: cache
    ports:
    - protocol: TCP
      port: 6379
```

### Secret Encryption

Advanced secret management with external secrets:

```yaml
# k8s/manifests/external-secrets.yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets-manager
  namespace: ai-agent-recruiter
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets-sa
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: ai-agent-recruiter-external-secrets
  namespace: ai-agent-recruiter
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: ai-agent-recruiter-secrets
    creationPolicy: Owner
  data:
  - secretKey: OPENAI_API_KEY
    remoteRef:
      key: ai-agent-recruiter/openai
      property: api_key
  - secretKey: DATABASE_PASSWORD
    remoteRef:
      key: ai-agent-recruiter/database
      property: password
```

## Performance Optimization

### Resource Optimization

Advanced resource management:

```yaml
# k8s/manifests/backend-deployment-optimized.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ai-agent-recruiter-backend
  namespace: ai-agent-recruiter
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 0
  template:
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: ai-agent-recruiter
            component: backend
      containers:
      - name: backend
        image: your-registry/ai-agent-recruiter-backend:latest
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
            ephemeral-storage: "1Gi"
          limits:
            memory: "2Gi"
            cpu: "1000m"
            ephemeral-storage: "2Gi"
        # JVM optimization for Python
        env:
        - name: PYTHONUNBUFFERED
          value: "1"
        - name: PYTHONDONTWRITEBYTECODE
          value: "1"
        - name: WEB_CONCURRENCY
          value: "4"
        # Health checks with proper timeouts
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 60
          periodSeconds: 30
          timeoutSeconds: 10
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /ready
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        startupProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 30
```

### Caching Strategy

Multi-layer caching configuration:

```yaml
# k8s/manifests/redis-cluster.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: redis-cluster
  namespace: ai-agent-recruiter
spec:
  serviceName: redis-cluster
  replicas: 3
  selector:
    matchLabels:
      app: redis-cluster
  template:
    metadata:
      labels:
        app: redis-cluster
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
        - containerPort: 16379
        command:
        - redis-server
        - /etc/redis/redis.conf
        env:
        - name: REDIS_CLUSTER_ANNOUNCE_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        volumeMounts:
        - name: config
          mountPath: /etc/redis
        - name: data
          mountPath: /data
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "200m"
      volumes:
      - name: config
        configMap:
          name: redis-cluster-config
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: "gp3"
      resources:
        requests:
          storage: 10Gi
```

## High Availability Setup

### Multi-AZ Deployment

Ensure high availability across availability zones:

```yaml
# k8s/manifests/backend-deployment-ha.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ai-agent-recruiter-backend
  namespace: ai-agent-recruiter
spec:
  replicas: 6  # 2 per AZ
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 50%
      maxUnavailable: 25%
  template:
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - ai-agent-recruiter
                - key: component
                  operator: In
                  values:
                  - backend
              topologyKey: kubernetes.io/hostname
          - weight: 50
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - ai-agent-recruiter
                - key: component
                  operator: In
                  values:
                  - backend
              topologyKey: topology.kubernetes.io/zone
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: ai-agent-recruiter
            component: backend
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: ScheduleAnyway
        labelSelector:
          matchLabels:
            app: ai-agent-recruiter
            component: backend
```

### Database High Availability

RDS Multi-AZ with read replicas:

```hcl
# k8s/terraform/rds-ha.tf
resource "aws_db_instance" "main" {
  identifier = "${local.name}-db"
  
  engine         = "postgres"
  engine_version = "15.3"
  instance_class = var.rds_instance_class
  
  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  
  # High Availability
  multi_az               = true
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  # Performance
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  monitoring_interval                   = 60
  monitoring_role_arn                  = aws_iam_role.rds_monitoring.arn
  
  # Security
  deletion_protection = var.environment == "production"
  
  tags = local.tags
}

# Read replica for read-heavy workloads
resource "aws_db_instance" "read_replica" {
  count = var.environment == "production" ? 2 : 0
  
  identifier = "${local.name}-db-read-${count.index + 1}"
  
  replicate_source_db = aws_db_instance.main.identifier
  instance_class      = var.rds_replica_instance_class
  
  # Performance
  performance_insights_enabled = true
  monitoring_interval         = 60
  monitoring_role_arn        = aws_iam_role.rds_monitoring.arn
  
  tags = merge(local.tags, {
    Name = "${local.name}-db-read-${count.index + 1}"
    Type = "read-replica"
  })
}
```

## Monitoring and Observability

### Comprehensive Monitoring Stack

```yaml
# k8s/manifests/monitoring-stack.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring
---
# Prometheus
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      evaluation_interval: 15s
    
    rule_files:
      - "/etc/prometheus/rules/*.yml"
    
    scrape_configs:
      - job_name: 'kubernetes-apiservers'
        kubernetes_sd_configs:
        - role: endpoints
        scheme: https
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        relabel_configs:
        - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
          action: keep
          regex: default;kubernetes;https
      
      - job_name: 'ai-agent-recruiter-backend'
        kubernetes_sd_configs:
        - role: pod
        relabel_configs:
        - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
          action: keep
          regex: true
        - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
          action: replace
          target_label: __metrics_path__
          regex: (.+)
        - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
          action: replace
          regex: ([^:]+)(?::\d+)?;(\d+)
          replacement: $1:$2
          target_label: __address__
        - action: labelmap
          regex: __meta_kubernetes_pod_label_(.+)
        - source_labels: [__meta_kubernetes_namespace]
          action: replace
          target_label: kubernetes_namespace
        - source_labels: [__meta_kubernetes_pod_name]
          action: replace
          target_label: kubernetes_pod_name
    
    alerting:
      alertmanagers:
      - static_configs:
        - targets:
          - alertmanager:9093
---
# Grafana Dashboard ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboards
  namespace: monitoring
data:
  ai-agent-recruiter-dashboard.json: |
    {
      "dashboard": {
        "id": null,
        "title": "AI Agent Recruiter Dashboard",
        "tags": ["ai-agent-recruiter"],
        "timezone": "browser",
        "panels": [
          {
            "title": "Request Rate",
            "type": "graph",
            "targets": [
              {
                "expr": "rate(http_requests_total{job=\"ai-agent-recruiter-backend\"}[5m])",
                "legendFormat": "{{method}} {{status}}"
              }
            ]
          },
          {
            "title": "Response Time",
            "type": "graph",
            "targets": [
              {
                "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{job=\"ai-agent-recruiter-backend\"}[5m])) * 1000",
                "legendFormat": "95th percentile"
              }
            ]
          },
          {
            "title": "Error Rate",
            "type": "singlestat",
            "targets": [
              {
                "expr": "rate(http_requests_total{job=\"ai-agent-recruiter-backend\",status=~\"5..\"}[5m]) / rate(http_requests_total{job=\"ai-agent-recruiter-backend\"}[5m]) * 100",
                "legendFormat": "Error Rate %"
              }
            ]
          }
        ]
      }
    }
```

### Custom Metrics

Application-specific metrics collection:

```python
# backend/app/metrics.py
from prometheus_client import Counter, Histogram, Gauge, generate_latest
import time
from functools import wraps

# Metrics
HTTP_REQUESTS = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

HTTP_REQUEST_DURATION = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration',
    ['method', 'endpoint']
)

ACTIVE_JOBS = Gauge(
    'active_jobs_total',
    'Number of active job listings'
)

JOB_SCRAPING_DURATION = Histogram(
    'job_scraping_duration_seconds',
    'Time spent scraping jobs',
    ['source']
)

AI_ANALYSIS_DURATION = Histogram(
    'ai_analysis_duration_seconds',
    'Time spent on AI analysis'
)

DATABASE_CONNECTIONS = Gauge(
    'database_connections_active',
    'Active database connections'
)

def track_request_metrics(f):
    @wraps(f)
    async def wrapper(*args, **kwargs):
        start_time = time.time()
        status = "200"
        try:
            result = await f(*args, **kwargs)
            return result
        except Exception as e:
            status = "500"
            raise
        finally:
            duration = time.time() - start_time
            HTTP_REQUEST_DURATION.labels(
                method="GET",  # Extract from request
                endpoint=f.__name__
            ).observe(duration)
            HTTP_REQUESTS.labels(
                method="GET",
                endpoint=f.__name__,
                status=status
            ).inc()
    return wrapper
```

## Backup and Disaster Recovery

### Automated Backup Strategy

```yaml
# k8s/manifests/backup-cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: database-backup
  namespace: ai-agent-recruiter
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: postgres:15
            command:
            - /bin/bash
            - -c
            - |
              set -e
              BACKUP_NAME="backup-$(date +%Y%m%d%H%M%S)"
              
              # Database backup
              pg_dump $DATABASE_URL > /tmp/${BACKUP_NAME}.sql
              
              # Upload to S3
              aws s3 cp /tmp/${BACKUP_NAME}.sql s3://${BACKUP_BUCKET}/database/${BACKUP_NAME}.sql
              
              # Cleanup old backups (keep 30 days)
              aws s3 ls s3://${BACKUP_BUCKET}/database/ | grep "backup-" | head -n -30 | awk '{print $4}' | xargs -I {} aws s3 rm s3://${BACKUP_BUCKET}/database/{}
            env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: ai-agent-recruiter-secrets
                  key: DATABASE_URL
            - name: BACKUP_BUCKET
              value: "ai-agent-recruiter-backups"
            - name: AWS_DEFAULT_REGION
              value: "us-east-1"
          restartPolicy: OnFailure
          serviceAccountName: backup-service-account
```

### Cross-Region Disaster Recovery

```hcl
# k8s/terraform/disaster-recovery.tf
# Cross-region RDS backup
resource "aws_db_instance" "disaster_recovery" {
  count = var.enable_disaster_recovery ? 1 : 0
  
  provider = aws.backup_region
  
  identifier = "${local.name}-dr"
  
  # Restore from snapshot
  snapshot_identifier = var.disaster_recovery_snapshot_id
  
  instance_class = var.rds_dr_instance_class
  
  # Minimal configuration for cost
  allocated_storage = 20
  storage_type      = "gp2"
  
  # Security
  vpc_security_group_ids = [aws_security_group.rds_dr[0].id]
  db_subnet_group_name   = aws_db_subnet_group.dr[0].name
  
  tags = merge(local.tags, {
    Purpose = "disaster-recovery"
  })
}

# S3 Cross-Region Replication
resource "aws_s3_bucket_replication_configuration" "disaster_recovery" {
  count = var.enable_disaster_recovery ? 1 : 0
  
  role   = aws_iam_role.s3_replication[0].arn
  bucket = aws_s3_bucket.assets.id
  
  rule {
    id     = "disaster-recovery"
    status = "Enabled"
    
    destination {
      bucket        = aws_s3_bucket.assets_dr[0].arn
      storage_class = "STANDARD_IA"
    }
  }
  
  depends_on = [aws_s3_bucket_versioning.assets]
}
```

## Cost Optimization

### Advanced Cost Management

```yaml
# k8s/manifests/cost-optimization.yaml
# Vertical Pod Autoscaler for right-sizing
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: ai-agent-recruiter-backend-vpa
  namespace: ai-agent-recruiter
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ai-agent-recruiter-backend
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: backend
      maxAllowed:
        cpu: 2
        memory: 4Gi
      minAllowed:
        cpu: 100m
        memory: 128Mi
      controlledResources: ["cpu", "memory"]
      controlledValues: RequestsAndLimits
---
# Cluster Autoscaler configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-autoscaler-status
  namespace: kube-system
data:
  nodes.max: "20"
  nodes.min: "3"
  scale-down-delay-after-add: "10m"
  scale-down-unneeded-time: "10m"
  scale-down-utilization-threshold: "0.5"
  skip-nodes-with-local-storage: "false"
  skip-nodes-with-system-pods: "false"
```

### Spot Instance Integration

```hcl
# k8s/terraform/spot-instances.tf
resource "aws_eks_node_group" "spot" {
  cluster_name    = module.eks.cluster_name
  node_group_name = "spot"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = module.vpc.private_subnets
  
  capacity_type  = "SPOT"
  instance_types = ["m5.large", "m5.xlarge", "m4.large", "m4.xlarge", "c5.large", "c5.xlarge"]
  
  scaling_config {
    desired_size = var.spot_desired_size
    max_size     = var.spot_max_size
    min_size     = var.spot_min_size
  }
  
  # Spot instance interruption handling
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
  
  labels = {
    "node-type" = "spot"
    "workload"  = "non-critical"
  }
  
  taint {
    key    = "spot"
    value  = "true"
    effect = "NO_SCHEDULE"
  }
  
  tags = merge(local.tags, {
    "k8s.io/cluster-autoscaler/enabled"                     = "true"
    "k8s.io/cluster-autoscaler/${module.eks.cluster_name}" = "owned"
    "k8s.io/cluster-autoscaler/node-template/label/node-type" = "spot"
  })
}
```

This advanced configuration provides enterprise-grade features including enhanced security, performance optimization, high availability, comprehensive monitoring, disaster recovery, and cost optimization. Each section can be customized based on specific requirements and compliance needs.