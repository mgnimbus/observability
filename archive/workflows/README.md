# EKS Terraform Workflows

This repository contains optimized GitHub Actions workflows for deploying and destroying EKS infrastructure with Terraform.

## 🚀 Features

- **Parallel Execution**: Components are deployed in stages with maximum parallelization
- **Dependency Management**: Proper ordering ensures resources are created/destroyed in the correct sequence
- **Reusable Workflows**: Reduces code duplication and improves maintainability
- **Caching**: Terraform providers and modules are cached for faster execution
- **Safety Controls**: Destroy workflow requires explicit confirmation
- **Comprehensive Reporting**: Job summaries and optional Slack notifications

## 📁 Workflow Files

### Deployment Workflows

1. **`deploy-workflow.yml`** - Basic deployment workflow with matrix strategy (auto-trigger)
2. **`deploy-workflow-dispatch.yml`** - Full-featured manual deployment with stage selection
3. **`deploy-workflow-optimized.yml`** - Optimized deployment using reusable workflows
4. **`deploy-simple-dispatch.yml`** - Simplified manual deployment for quick deployments
5. **`terraform-apply-reusable.yml`** - Reusable workflow for Terraform operations

### Destroy Workflow

6. **`destroy-workflow.yml`** - Infrastructure destruction workflow (manual trigger only)

### Choosing the Right Workflow

| Use Case | Recommended Workflow | Key Features |
|----------|---------------------|--------------|
| Automated CI/CD | `deploy-workflow.yml` | Auto-triggers on push/PR |
| Manual deployments with full control | `deploy-workflow-dispatch.yml` | Stage selection, dry-run, environment choice |
| Quick manual deployments | `deploy-simple-dispatch.yml` | Simple 3-option deployment |
| Minimize code duplication | `deploy-workflow-optimized.yml` | Uses reusable workflows |
| Destroy infrastructure | `destroy-workflow.yml` | Safe destruction with confirmation |

## 🏗️ Deployment Stages

### Stage 1 (Parallel)
- `_1_eks` - EKS Cluster
- `_3_backend` - Backend infrastructure

### Stage 2 (Parallel) - Depends on Stage 1
- `_1.2.1loadbalancer` - Load Balancer
- `_1.4_cert` - Certificate management

### Stage 3 (Parallel) - Depends on Stage 2
- `_1.2.2_nginx_ingress` - NGINX Ingress Controller
- `_2_grafana` - Grafana monitoring
- `_4_loki` - Loki log aggregation
- `_7_otel_operator` - OpenTelemetry Operator

### Stage 4 (Parallel) - Depends on Stage 3
- `_8_otel_collector` - OpenTelemetry Collector
- `_meta_monitoring` - Meta monitoring setup

## 🔧 Setup

### Prerequisites

1. **AWS Credentials**: Set up the following secrets in your GitHub repository:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`

2. **Terraform State**: Ensure your Terraform configurations use remote state (S3 + DynamoDB recommended)
   - State paths follow pattern: `{environment}/{component}/terraform.tfstate`
   - Enable state locking with DynamoDB

3. **Directory Structure**: Your repository should have the following structure:
   ```
   .
   ├── _1_eks/
   ├── _1.2.1loadbalancer/
   ├── _1.2.2_nginx_ingress/
   ├── _1.4_cert/
   ├── _2_grafana/
   ├── _3_backend/
   ├── _4_loki/
   ├── _7_otel_operator/
   ├── _8_otel_collector/
   ├── _meta_monitoring/
   └── .github/workflows/
   ```

4. **Terraform Module Requirements**:
   - EKS module must output `cluster_name`
   - All modules should support `environment` variable
   - Use consistent provider versions

### Optional Configuration

- **Slack Notifications**: Add `SLACK_WEBHOOK_URL` to repository variables for deployment notifications
- **GitHub Environments**: Create environments (development, staging, production) with protection rules

## 🚀 Usage

### Automatic Deployment

The deployment workflow triggers automatically on:
- Push to `main` branch
- Pull requests to `main` branch

### Manual Deployment (Workflow Dispatch)

For more control over deployments, use the manual workflow dispatch:

1. Go to the Actions tab in GitHub
2. Select "EKS-With-Terraform CD (Manual/Auto)" workflow
3. Click "Run workflow"
4. Configure the deployment options:

#### Workflow Dispatch Options

| Option | Description | Default | Options |
|--------|-------------|---------|---------|
| **Deploy Stage** | Which stages to deploy | `all` | • `all` - Deploy all stages<br>• `stage1-only` - Only EKS & Backend<br>• `stage2-only` - Only LB & Cert<br>• `stage3-only` - Only monitoring tools<br>• `stage4-only` - Only collectors<br>• `from-stage2` - Stage 2, 3, 4<br>• `from-stage3` - Stage 3, 4<br>• `from-stage4` - Only stage 4 |
| **Dry Run** | Plan only, no apply | `false` | `true` / `false` |
| **Environment** | Target environment | `production` | `development`, `staging`, `production` |
| **Skip Validation** | Skip fmt & validate | `false` | `true` / `false` |
| **Terraform Parallelism** | Parallelism level | `20` | `10` - `50` |

#### Workflow Dispatch Comparison

| Feature | `deploy-workflow-dispatch.yml` | `deploy-simple-dispatch.yml` |
|---------|-------------------------------|----------------------------|
| **Complexity** | Full control | Simple 3-option |
| **Stage Selection** | 8 options (granular) | All or skip monitoring |
| **Use Case** | Complex deployments | Quick deployments |
| **Options** | 5 parameters | 3 parameters |
| **Best For** | DevOps teams | Developers |

#### Example Scenarios

**Full Production Deployment:**
- Deploy Stage: `all`
- Environment: `production`
- Dry Run: `false`

**Test Changes in Staging:**
- Deploy Stage: `all`
- Environment: `staging`
- Dry Run: `true` (first run)
- Dry Run: `false` (after review)

**Update Only Monitoring Stack:**
- Deploy Stage: `from-stage3`
- Environment: `production`
- Skip Validation: `true` (if confident)

**Quick Cert Update:**
- Deploy Stage: `stage2-only`
- Environment: `production`ptions |
|--------|-------------|---------|---------|
| **Deploy Stage** | Which stages to deploy | `all` | • `all` - Deploy all stages<br>• `stage1-only` - Only EKS & Backend<br>• `stage2-only` - Only LB & Cert<br>• `stage3-only` - Only monitoring tools<br>• `stage4-only` - Only collectors<br>• `from-stage2` - Stage 2, 3, 4<br>• `from-stage3` - Stage 3, 4<br>• `from-stage4` - Only stage 4 |
| **Dry Run** | Plan only, no apply | `false` | `true` / `false` |
| **Environment** | Target environment | `production` | `development`, `staging`, `production` |
| **Skip Validation** | Skip fmt & validate | `false` | `true` / `false` |
| **Terraform Parallelism** | Parallelism level | `20` | `10` - `50` |

#### Example Scenarios

**Full Production Deployment:**
- Deploy Stage: `all`
- Environment: `production`
- Dry Run: `false`

**Test Changes in Staging:**
- Deploy Stage: `all`
- Environment: `staging`
- Dry Run: `true` (first run)
- Dry Run: `false` (after review)

**Update Only Monitoring Stack:**
- Deploy Stage: `from-stage3`
- Environment: `production`
- Skip Validation: `true` (if confident)

**Quick Cert Update:**
- Deploy Stage: `stage2-only`
- Environment: `production`

### Destruction

To destroy the infrastructure:

1. Go to Actions tab in GitHub
2. Select "EKS-Terraform-Destroy" workflow
3. Click "Run workflow"
4. Type `destroy` in the confirmation field
5. Click "Run workflow" to start destruction

⚠️ **Warning**: The destroy workflow will remove ALL resources. Use with caution!

### Environment-Specific Deployments

When using workflow dispatch, you can deploy to different environments:

```yaml
# Development
environment: development
dry_run: true  # Test first

# Staging  
environment: staging
dry_run: false

# Production
environment: production
dry_run: false
skip_validation: false  # Always validate prod
```

## ⚡ Optimization Tips

1. **Terraform Version**: Keep all modules using the same Terraform version for consistency
2. **State Locking**: Use DynamoDB for state locking to prevent concurrent modifications
3. **Module Outputs**: Ensure EKS module exports `cluster_name` for dependent resources
4. **Resource Tagging**: Use consistent tags across all resources for cost tracking
5. **Timeouts**: Consider adding timeouts for long-running resources

## 🔍 Monitoring Workflow Execution

- Check the Actions tab for real-time progress
- Review job summaries for deployment status
- Check Slack notifications (if configured)
- Use workflow run logs for debugging

## 🛠️ Troubleshooting

### Common Issues

1. **Kubeconfig Update Fails**
   - Ensure EKS cluster is fully created before dependent resources
   - Check if `cluster_name` output exists in EKS module

2. **Terraform State Lock**
   - Check DynamoDB for stuck locks
   - Use force-unlock if necessary (with caution)

3. **AWS Permissions**
   - Ensure IAM role/user has necessary permissions for all resources
   - Check CloudTrail logs for permission denials

4. **Parallel Job Failures**
   - Jobs run with `continue-on-error` for destroy operations
   - Check individual job logs for specific errors

## 📊 Performance Metrics

With parallel execution, typical deployment times:
- Stage 1: ~15-20 minutes (EKS creation)
- Stage 2: ~5 minutes
- Stage 3: ~5-10 minutes
- Stage 4: ~5 minutes
- **Total**: ~30-40 minutes (vs ~60-90 minutes sequential)

## 🔐 Security Best Practices

1. Use OIDC for AWS authentication instead of long-lived credentials
2. Restrict workflow permissions to minimum required
3. Enable branch protection rules for `main`
4. Review and approve infrastructure changes via PR process
5. Regularly rotate AWS credentials
6. Use separate AWS accounts for different environments

## 📝 Contributing

When adding new Terraform modules:
1. Determine the appropriate deployment stage based on dependencies
2. Update workflow files to include the new module
3. Ensure module outputs are properly configured
4. Test in a development environment first
5. Document any new requirements or dependencies