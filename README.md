# Modular AWS SaaS Cloud Platform (Terraform)

[![Terraform](https://img.shields.io/badge/Terraform-v1.5+-623CE4.svg?logo=terraform)](https://www.terraform.io/)
[![AWS Provider](https://img.shields.io/badge/AWS%20Provider-v5.0+-FF9900.svg?logo=amazon-aws)](https://registry.terraform.io/providers/hashicorp/aws/latest)
[![Compliance](https://img.shields.io/badge/Compliance-NIST%20800--53%20%7C%20SOC%202%20%7C%20CIS-00C853.svg)](#compliance--security-controls-matrix)

Modular Infrastructure as Code (IaC) architecting an enterprise **Multi-Tier SaaS Platform** on AWS, featuring **AWS ECS Fargate**, **Amazon Aurora MySQL Multi-AZ**, and **ElastiCache Redis**.

Built from the ground up to support **institutional enterprise governance**, **SOC 2 Type II**, **HITRUST CSF**, and **NIST SP 800-53 Rev 5** compliance baselines while empowering engineering teams with automated, self-service container deployments ("Golden Paths").

> **System Design Document (SDD):** See [`docs/SDD.md`](docs/SDD.md) for the complete architectural specification, module deep-dives, sequence diagrams, and regulatory control mappings.

---

## 1. Architecture Blueprint

```text
                              [ Internet ]
                                   │
                                   ▼
                      ┌─────────────────────────┐
                      │    AWS WAF v2 WebACL    │ (OWASP Top 10, Bad Inputs,
                      │  (Rate Limiting & IP)   │  IP Reputation, 2k req/5m)
                      └────────────┬────────────┘
                                   │
                                   ▼
                      ┌─────────────────────────┐
                      │ Public Application LB   │ (HTTPS TLS 1.2+ Enforced,
                      │   (us-west-2a/b/c)      │  HTTP-to-HTTPS 301 Redirect)
                      └────────────┬────────────┘
                                   │ (traffic strictly on container_port)
                                   ▼
       ┌─────────────────────────────────────────────────────────┐
       │   Private Application Subnets (ECS Fargate - awsvpc)    │
       │                                                         │
       │   ┌─────────────────────┐     ┌─────────────────────┐   │
       │   │   ECS Web Service   │     │  ECS Worker Service │   │
       │   │  (API / Web Fleet)  │     │ (Async Queue Fleet) │   │
       │   │ Auto-scaling (CPU/M)│     │  (php artisan work) │   │
       │   └──────────┬──────────┘     └──────────┬──────────┘   │
       └──────────────┼───────────────────────────┼──────────────┘
                      │ (Port 3306)               │ (Port 6379)
                      ▼                           ▼
       ┌───────────────────────────┐ ┌───────────────────────────┐
       │ Isolated Database Subnets │ │ Isolated Database Subnets │
       │  Amazon Aurora MySQL 8.0  │ │  ElastiCache Redis 7.x    │
       │ Multi-AZ Cluster (Writer  │ │  Replication Group (Auth  │
       │  + Read Replicas, KMS)    │ │  Token, In-Transit TLS)   │
       └───────────────────────────┘ └───────────────────────────┘
                      ▲                           ▲
                      └─────────────┬─────────────┘
                                    │
       ┌────────────────────────────┴────────────────────────────┐
       │     Encrypted S3 Document Vault (Contracts & Assets)    │
       │   (KMS CMK, Versioning, Access Logs, TLS 1.2+ Only)     │
       └─────────────────────────────────────────────────────────┘
```

---

## 2. Tech Stack & Modernization Mapping

| Component | Legacy Infrastructure Pattern | Modern Cloud-Native AWS Blueprint |
| :--- | :--- | :--- |
| **Compute Runtime** | Standalone monolithic VMs (manual Nginx/PHP-FPM) | **AWS ECS Fargate** (Serverless, containerized, zero-downtime rolling deploys) |
| **Relational Database** | Single-node MySQL VM / non-HA DB | **Amazon Aurora MySQL 8.0 Multi-AZ** (Automated failover, KMS encryption, 30-day backups) |
| **Session & Queues** | Local file sessions / basic queue worker | **Amazon ElastiCache Redis 7.x** (In-transit TLS, Multi-AZ replication, auth token) |
| **Document Storage** | Local VM disk / basic block storage | **Amazon S3 Document Vault** (KMS CMK, versioning, access logging, Glacier transition) |
| **Shared File Storage** | Local host shared disk | **Amazon EFS** (KMS CMK encrypted, multi-AZ mount targets, POSIX access points) |
| **Scheduled Tasks** | Linux host crontab entries | **AWS EventBridge + ECS RunTask** (Scheduled container execution every minute) |
| **Edge & Perimeter** | Basic DNS proxy | **AWS WAF v2 WebACL + ALB** (AWS Managed Common Rules, Known Bad Inputs, rate limiting) |
| **Observability & APM** | Ad-hoc server logs | **AWS CloudWatch Container Insights + APM Tracing + Sentry Error Hooks** |
| **AI Integration** | None | **AWS Bedrock Foundation Model Integration** (Anthropic Claude 3.5 Sonnet) |
| **CI/CD Automation** | Manual SSH / Git pull on hosts | **GitHub Actions Keyless OIDC Deploy** (`.github/workflows/deploy.yml`) |
| **Internal DNS** | Hardcoded `/etc/hosts` files | **Amazon Route53 Private Hosted Zone** (`.internal` DNS for Aurora, Redis, ALB) |
| **Compliance Automation**| Manual audit spreadsheets | **Automated Security & Compliance Auditor Roles** (`aws_iam_role.vanta_auditor`) |
| **Secrets Management**| Unencrypted `.env` files on disk | **AWS Secrets Manager** (KMS encrypted, dynamically injected into ECS containers) |

---

## 3. Compliance & Security Controls Matrix

This repository enforces controls mapped across four major security and regulatory frameworks:

### A. NIST SP 800-53 Rev 5 Controls
* **AC-2 / AC-3 (Access Control & Least Privilege):** Separate IAM Task Execution Role (infrastructure-level pulls/logs) and Task Role (application runtime S3 access only). Default security groups hardened with zero inbound/outbound rules (CIS 4.3).
* **AC-4 (Information Flow Enforcement):** Strict 3-tier VPC segmentation. Database subnets have zero internet route table entries; ingress restricted strictly to application security groups.
* **AU-2 / AU-12 (Audit & Monitoring):** VPC Flow Logs enabled across all subnets to KMS-encrypted CloudWatch log groups with 90-day retention. ECS Container Insights enabled.
* **CP-9 / CP-10 (Information System Backup):** Aurora automated backups configured with 30-day retention and point-in-time recovery. S3 bucket versioning enabled.
* **IA-5 (Authenticator Management):** Master database credentials and Redis auth tokens generated using high-entropy random secrets and stored in KMS-encrypted Secrets Manager.
* **SC-7 (Boundary Protection):** AWS WAF v2 applied to public ALB inspecting for OWASP Top 10 vulnerabilities, IP reputation lists, and volumetric rate limits.
* **SC-8 (Transmission Confidentiality):** S3 bucket policies explicitly deny non-TLS requests (`aws:SecureTransport = false`). ALB enforces TLS 1.2+ security policies. Redis in-transit encryption enabled.
* **SC-12 / SC-13 (Cryptographic Key Management):** Dedicated Customer Managed Keys (CMKs) with automatic annual rotation enabled (`enable_key_rotation = true`) for Storage, Database, and CloudWatch Logs.

### B. CIS AWS Foundations Benchmark
* **CIS 2.1.1 - 2.1.4 (S3 Security):** All S3 buckets enforce public access blocks (all 4 flags), KMS CMK server-side encryption, versioning, and server access logging.
* **CIS 2.3.1 (RDS Encryption):** Aurora MySQL storage encrypted at rest using dedicated KMS CMK.
* **CIS 2.4.1 (ALB HTTPS):** Application Load Balancer enforces modern TLS 1.2+ cipher suites (`ELBSecurityPolicy-TLS13-1-2-2021-06`) and drops invalid HTTP headers.
* **CIS 2.8 (KMS Rotation):** All KMS keys configured with annual rotation enabled.
* **CIS 3.9 (VPC Flow Logs):** VPC Flow Logging active with CloudWatch destination.
* **CIS 4.3 (Default Security Group):** Default VPC security group strips all inbound and outbound rules.

### C. SOC 2 Type II & HITRUST CSF Alignment
* **CC6.1 / CC6.6 (Logical Access & Boundary Defense):** Zero `0.0.0.0/0` ingress rules on any application, database, or cache security group. All east-west traffic authorized strictly by source security group ID.
* **CC6.7 (Data Transmission):** End-to-end encryption in transit (HTTPS external $\rightarrow$ TLS 1.2+ internal).
* **CC7.1 (System Monitoring):** CloudWatch alarms, structured JSON logging, and Container Insights.

---

## 4. Repository Structure

```text
terraform-aws-production-saas-blueprint/
├── .gitignore
├── versions.tf                  # Provider versions (AWS ~> 5.0, Terraform >= 1.5.0)
├── variables.tf                 # Global configuration variables
├── main.tf                      # Root module orchestrating all subsystems
├── outputs.tf                   # Root deployment outputs (ALB DNS, DB endpoints, etc.)
├── terraform.tfvars.example     # Sample environment configuration
├── README.md                    # Platform documentation & compliance matrix
├── docs/
│   └── SDD.md                   # Full System Design Document & Architectural Spec
└── modules/
    ├── vpc/                     # 3-tier VPC (Public, App, Isolated DB) + Flow Logs + Endpoints
    ├── ecs/                     # ECS Fargate Cluster, Task Definitions, ALB, Auto-Scaling
    ├── database/                # Amazon Aurora MySQL 8.0 Multi-AZ Cluster + Secrets Manager
    ├── redis/                   # ElastiCache Redis 7.x Replication Group + Auth Token
    ├── efs/                     # Shared persistent container storage + Access Points
    ├── s3/                      # Encrypted Document Vault + Server Access Logs
    ├── kms/                     # Dedicated KMS CMKs with annual rotation
    ├── security/                # AWS WAF v2, Security Groups, IAM Roles (Execution/Task)
    ├── route53/                 # Private Hosted Zone (.internal) for microservice discovery
    └── migration/               # Automated ECS RunTask DB migration tasks & cutover metrics
```

---

## 5. Deployment Runbook

### Prerequisites
1. **Terraform CLI:** `>= 1.5.0` (or OpenTofu `>= 1.6.0`)
2. **AWS CLI:** Authenticated with deployment credentials (`us-west-2` or preferred region)
3. **ACM Certificate:** Pre-provisioned SSL certificate ARN in AWS Certificate Manager for your domain.

### Quickstart

```bash
# 1. Clone repository
git clone https://github.com/paulkanz/terraform-aws-production-saas-blueprint.git
cd terraform-aws-production-saas-blueprint

# 2. Create environment configuration
cp terraform.tfvars.example terraform.tfvars

# 3. Edit variables with your ACM certificate ARN and desired parameters
vim terraform.tfvars

# 4. Initialize Terraform
terraform init

# 5. Review plan
terraform plan -out=tfplan

# 6. Apply infrastructure
terraform apply tfplan
```

---

## 6. Developer Self-Service ("Golden Paths")

Application developers do not need to configure VPCs, IAM roles, or load balancers manually. To ship code:

1. **Docker Build & Push:** GitHub Actions builds the Docker image and tags it with the commit SHA:
   ```bash
   docker build -t 123456789012.dkr.ecr.us-west-2.amazonaws.com/app-web:v1.2.3 .
   docker push 123456789012.dkr.ecr.us-west-2.amazonaws.com/app-web:v1.2.3
   ```
2. **Automated Deploy:** CI updates the ECS Task Definition image tag:
   ```bash
   aws ecs update-service \
     --cluster saas-prod-cluster \
     --service saas-prod-web-service \
     --force-new-deployment
   ```
3. **Zero Downtime:** ECS spins up new Fargate tasks, waits for `/up` health checks to return `200 OK` on the ALB target group, and gracefully drains old tasks without dropping a single user request.

---

## 7. License & Maintainer

Maintained by **Paul Kanz** (Staff Platform & Infrastructure Architect).  
Licensed under the Apache License 2.0.
