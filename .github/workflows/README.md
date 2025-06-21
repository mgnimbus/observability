# EKS Infrastructure Workflows

This repository contains simplified GitHub Actions workflows for deploying and destroying EKS infrastructure.

## Deployment Flow

```

## Destroy Flow

When destroying infrastructure, the following order is maintained:

```
Destroy Order (Reverse of deployment)
│
├── 1. Monitoring Stack (if deployed)
│   ├── Meta Monitoring
│   ├── OTel Collector
│   ├── OTel Operator
│   ├── Loki
│   ├── Grafana
│   └── Nginx Ingress
│
├── 2. Secondary Infrastructure
│   ├── Certificates
│   └── Load Balancer
│
└── 3. Primary Infrastructure
    ├── EKS Cluster ✅ DESTROYED
    └── S3 Backend  ❌ PRESERVED (contains Terraform state)
```
Primary Infrastructure (Parallel)
├── EKS Cluster (~20 min)
└── S3 Backend (Quick) - ⚠️ NEVER DESTROYED
    ↓
Secondary Infrastructure (After EKS ready)
├── Load Balancer
└── Certificates
    ↓
Monitoring Stack (Optional)
├── Nginx Ingress
├── Grafana
├── Loki
├── OTel Operator
├── OTel Collector (depends on operator)
└── Meta Monitoring (depends on others)
```

## Workflows

### 1. Deploy/Destroy Workflow (`deploy.yml`)

A unified workflow that can either deploy or destroy your infrastructure.

**Trigger**: Manual dispatch only

**Inputs**:
- `action`: Choose between `deploy` or `destroy`
- `deploy_monitoring`: Whether to include the monitoring stack (true/false)

**Usage**:
```bash
# Deploy infrastructure with monitoring
Action: deploy
Include monitoring: true

# Deploy without monitoring
Action: deploy
Include monitoring: false

# Destroy everything
Action: destroy
Include monitoring: true
```

### 2. Dedicated Destroy Workflow (`destroy.yml`) - Optional

A safer destroy workflow that handles components in reverse dependency order and preserves the S3 backend.

**Trigger**: Manual dispatch only

**Inputs**:
- `confirm_destroy`: Must type "DESTROY" to confirm (safety check)

**What it does**:
- Destroys all infrastructure EXCEPT the S3 backend
- Handles components in reverse order for safety
- Requires explicit confirmation

**Usage**:
- Navigate to Actions tab
- Select "EKS Destroy" workflow
- Click "Run workflow"
- Type "DESTROY" in the confirmation field
- Click "Run workflow"

## Components

### Primary Infrastructure
1. **EKS Cluster** (`_1_eks`) - ~20 minutes to deploy, destroyed on teardown
2. **S3 Backend** (`_3_s3_backend`) - Quick deploy, **NEVER DESTROYED** (contains Terraform state)

### Secondary Infrastructure (deployed after EKS completes)
3. **Load Balancer** (`_1.2.1load_balancer`) - depends on EKS
4. **Certificates** (`_1.4_cert`) - depends on EKS

### Monitoring Stack (optional, deployed last, destroyed first)
1. Nginx Ingress (`_1.2.2_nginx_ingress`)
2. Grafana (`_2_grafana`)
3. Loki (`_4_loki`)
4. OpenTelemetry Operator (`_7_otel_operator`)
5. OpenTelemetry Collector (`_8_otel_collector`) - depends on operator
6. Meta Monitoring (`_meta_monitoring`) - depends on other monitoring components

## Required Secrets

Configure these in your GitHub repository settings:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

## Important Notes

- **S3 Backend is never destroyed** - It contains your Terraform state files and is preserved during destroy operations
- The backend state file is versioned in the repository (no dynamic creation needed)
- All resources are deployed to `ap-south-2` region
- Terraform version `1.12.2` is used
- Primary infrastructure (EKS + S3) deploys in parallel, then secondary infrastructure (LB + Cert) deploys after EKS completes
- This optimization saves ~20 minutes by not blocking the loadbalancer and cert on S3 backend completion
- Destroy operations should preferably use the dedicated destroy workflow for safety