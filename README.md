# 🚀 AWS GitOps Platform: Highly Available Containerized Microservice with Passwordless GitHub Actions OIDC CI/CD

[![Terraform](https://img.shields.io/badge/Terraform-1.11.0-844FBA?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-CI%2FCD-2088FF?logo=github-actions&logoColor=white)](https://github.com/features/actions)
[![Docker](https://img.shields.io/badge/Docker-Container-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![FastAPI](https://img.shields.io/badge/FastAPI-Python-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![Security: Checkov](https://img.shields.io/badge/Security-Checkov-blueviolet)](https://www.checkov.io/)
[![Security: Trivy](https://img.shields.io/badge/Security-Trivy-blue)](https://trivy.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

An enterprise-grade, GitOps-driven cloud platform provisioned on **Amazon Web Services (AWS)** using **Terraform** and fully automated through **two-speed GitHub Actions CI/CD pipelines** powered by passwordless **AWS IAM OpenID Connect (OIDC)** authentication.

---

## 🏛️ System Architecture

```mermaid
flowchart TD
    subgraph GitHub ["🐙 GitHub Repository (russelmagtibay/aws-gitops-platform)"]
        direction TB
        Code["Codebase: modules/, environments/, app/"]
        P1["Pipeline 1: Infrastructure CI/CD<br/>(terraform.yml)"]
        P2["Pipeline 2: Application CI/CD<br/>(app.yml)"]
    end

    subgraph Security ["🔒 Identity & Governance (bootstrap/)"]
        OIDC["AWS IAM OIDC Provider<br/>token.actions.githubusercontent.com"]
        RolePlan["IAM Role: gha-plan<br/>(Read-Only Preview)"]
        RoleApply["IAM Role: gha-apply<br/>(Admin Provisioning)"]
        RoleApp["IAM Role: gha-app-deploy<br/>(ECR + ECS Only)"]
        S3State["Amazon S3 Remote State Bucket<br/>(AES256, TLS-Only, Native State Locking)"]
    end

    subgraph AWS ["☁️ AWS Cloud (ap-southeast-1 Singapore)"]
        subgraph VPC ["Custom VPC (10.0.0.0/16)"]
            subgraph PublicAZ1 ["Public Subnet (ap-southeast-1a)"]
                ALB1["Application Load Balancer (Port 80)"]
                NAT["NAT Gateway"]
            end
            subgraph PublicAZ2 ["Public Subnet (ap-southeast-1b)"]
                ALB2["ALB Listener"]
            end

            subgraph PrivateAZ1 ["Private Subnet (ap-southeast-1a)"]
                Task1["ECS Fargate Container<br/>(Python FastAPI / Ebook UI)"]
            end
            subgraph PrivateAZ2 ["Private Subnet (ap-southeast-1b)"]
                Task2["ECS Fargate Container<br/>(Python FastAPI / Ebook UI)"]
            end
        end

        ECR["Amazon ECR Private Registry<br/>(Vulnerability Scanning, 30-day Lifecycle)"]
        CW["Amazon CloudWatch<br/>(Metrics, Alarms, Container Logs)"]
    end

    P1 -->|AssumeRoleWithWebIdentity| RolePlan
    P1 -->|AssumeRoleWithWebIdentity| RoleApply
    P2 -->|AssumeRoleWithWebIdentity| RoleApp

    OIDC --- RolePlan
    OIDC --- RoleApply
    OIDC --- RoleApp

    RolePlan -.->|Read State| S3State
    RoleApply -->|Manage State & Resources| S3State
    RoleApply -->|Deploy IaC| VPC

    P2 -->|Docker Push| ECR
    P2 -->|Update Service| Task1
    P2 -->|Update Service| Task2

    ECR -->|Pull Image| Task1
    ECR -->|Pull Image| Task2
    ALB1 -->|HTTP 8000 /health| Task1
    ALB2 -->|HTTP 8000 /health| Task2
    Task1 -.->|Outbound via NAT| ECR
    Task2 -.->|Outbound via NAT| ECR
```

---

## 🌟 Key Engineering Highlights

### 1. Zero-Trust Passwordless CI/CD via AWS IAM OIDC
- **Zero Static AWS Secrets:** Absolutely no long-lived `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` stored in GitHub Secrets.
- **Federated Authentication:** GitHub Actions assumes temporary, short-lived STS credentials via an OIDC Identity Provider (`token.actions.githubusercontent.com`).
- **Strict Least-Privilege Scoping:**
  - `aws-gitops-platform-gha-plan`: Read-only permissions for generating Pull Request previews.
  - `aws-gitops-platform-gha-apply`: Broad infrastructure deployment permissions, strictly gated behind GitHub's **`production` Environment Approval Gate**.
  - `aws-gitops-platform-gha-app-deploy`: Scoped solely to ECR image pushing and ECS task definition updates.

### 2. Two-Speed GitOps Release Pipelines

| Pipeline | Trigger Path | Quality & Security Gates (CI) | Deployment Delivery (CD) |
| :--- | :--- | :--- | :--- |
| **Pipeline 1: Infrastructure** (`terraform.yml`) | `modules/**`, `environments/**` | `terraform fmt`, `terraform validate`, `TFLint`, **Checkov IaC Scanner** | Automated PR plan comment ➔ **Manual Approval Gate** ➔ `terraform apply` |
| **Pipeline 2: Application** (`app.yml`) | `app/**` | Python `pytest` unit testing, Docker non-root build, **Trivy Container Scanner** | Automated push to Amazon ECR ➔ **Zero-Downtime ECS Rolling Update** |

### 3. Highly Available & Fault-Tolerant Multi-AZ Architecture
- **Dual Availability Zones:** Deployed across `ap-southeast-1a` and `ap-southeast-1b` in Singapore.
- **Network Isolation:** Public Load Balancer terminates incoming traffic on Port 80 and proxies requests to ECS tasks running in isolated **Private Subnets** on Port 8000.
- **Zero-Downtime Rolling Updates:** ECS Fargate rolling deployments with `minimum_healthy_percent = 100` and `maximum_percent = 200`.
- **Automated Circuit-Breaker Rollbacks:** Automatic task rollback if health checks fail during deployment, guaranteeing 100% uptime.

### 4. Enterprise FinOps (Cost Optimization)
- Infrastructure can be provisioned in **3 minutes** via GitHub Actions and torn down in **2 minutes** via `terraform destroy`, preventing idle charges from NAT Gateways and Load Balancers while maintaining \$0.00 idle cost.
- Persistent S3 state bucket and IAM OIDC roles remain intact at **\$0.00/month**.

---

## 📂 Repository Directory Structure

```text
.
├── .github/
│   └── workflows/
│       ├── terraform.yml       # Pipeline 1: Infrastructure CI/CD with approval gate
│       └── app.yml             # Pipeline 2: Application CI/CD (Pytest, Trivy, ECR, ECS)
├── app/
│   ├── static/                 # Frontend landing page UI (HTML, CSS, JS, Images)
│   ├── Dockerfile              # Hardened, non-root Python 3.12 container specification
│   ├── main.py                 # FastAPI backend with /health check and static mounting
│   ├── requirements.txt        # Application and test dependencies
│   └── test_main.py            # Automated pytest unit test suite
├── bootstrap/
│   ├── backend.tf              # Remote backend migration for bootstrap state
│   ├── github-oidc.tf          # IAM OIDC Provider & 3 scoped least-privilege roles
│   ├── output.tf               # Exported ARNs and repository variables
│   ├── providers.tf            # AWS Provider configuration
│   ├── state-bucket.tf         # S3 state bucket with encryption, TLS & versioning
│   └── variable.tf             # Input variables for bootstrap phase
├── environments/
│   └── dev/
│       ├── main.tf             # Root module linking all infrastructure modules
│       ├── outputs.tf          # Live ALB DNS, ECR URL, and Cluster outputs
│       ├── providers.tf        # AWS Provider & S3 backend with native state locking
│       └── variables.tf        # Environment-specific configuration variables
└── modules/
    ├── alb/                    # Application Load Balancer & Target Groups
    ├── ecr/                    # Container registry with lifecycle retention policy
    ├── ecs/                    # ECS Cluster, Task Definition & Fargate Service
    ├── monitoring/             # CloudWatch Alarms & SNS Topic alerting
    ├── security/               # Security Groups & ECS IAM execution/task roles
    └── vpc/                    # Multi-AZ VPC, Public/Private Subnets & NAT Gateway
```

---

## 🚀 Deployment Guide

### Prerequisites
- [AWS CLI v2](https://aws.amazon.com/cli/) configured with an administrative profile.
- [Terraform >= 1.11.0](https://www.terraform.io/downloads.html).
- [GitHub CLI (`gh`)](https://cli.github.com/).

### Phase 1: Bootstrap Identity & Remote State
1. Navigate to the bootstrap directory:
   ```bash
   cd bootstrap
   terraform init
   terraform apply
   ```
2. Save the output IAM Role ARNs and S3 Bucket Name as **GitHub Repository Variables** under `Settings > Secrets and variables > Actions > Variables`:
   - `AWS_REGION`
   - `TF_STATE_BUCKET`
   - `AWS_PLAN_ROLE_ARN`
   - `AWS_APPLY_ROLE_ARN`
   - `AWS_APP_DEPLOY_ROLE_ARN`
3. Configure GitHub Environment:
   - Create an environment named **`production`**.
   - Add yourself as a **Required Reviewer** to enforce approval gates.

### Phase 2: Deploy Infrastructure via GitHub Actions
1. Push any Terraform change or manually trigger **Pipeline 1** via the GitHub Actions tab.
2. Review the automated `terraform plan` output generated in the Pull Request or workflow log.
3. Approve the **`production`** deployment gate.
4. Access the live endpoint output by the workflow:
   ```text
   http://<ALB-DNS-NAME>/
   ```

### Phase 3: Deploy Application Updates
1. Modify any frontend or backend code inside `app/`.
2. Commit and push directly to `main`:
   ```bash
   git add app/
   git commit -m "feat: enhance UI and add new feature"
   git push origin main
   ```
3. **Pipeline 2** automatically runs unit tests, scans the image with Trivy, pushes the tagged image to Amazon ECR, and executes a zero-downtime rolling update on ECS Fargate.

---

## 🧹 Teardown (Cost Optimization)

To cleanly destroy all compute and networking resources while maintaining your remote state bucket and OIDC trust:

```bash
cd environments/dev
terraform destroy -auto-approve
```

All AWS billable compute resources (NAT Gateway, Load Balancer, Fargate tasks) will be terminated, returning ongoing costs to **\$0.00**.

---

## 👤 Author

**Russel Magtibay**  
- **GitHub:** [@russelmagtibay](https://github.com/russelmagtibay)
- **Role:** Aspiring Cloud & DevOps Engineer
- **Specialization:** AWS Infrastructure as Code (Terraform), GitOps CI/CD Pipelines, Container Orchestration (Docker/ECS), Cloud Security & FinOps.
