# DevOps Technical Challenge - Infrastructure

Deploy a containerized Flask application to AWS using Terraform and GitHub Actions.

> **Note**: This project is designed to run on a new AWS account (e.g., AWS Educate/Starter with $100 credit). The infrastructure is cost-optimized but includes enterprise-grade features like load balancing and OIDC security.

## 🏗️ What This Repo Creates

This repository provisions the foundational infrastructure required to host the application:

| Component | Resource | Description |
|-----------|----------|-------------|
| **Networking** | VPC | 2 Public Subnets across 2 Availability Zones for high availability. |
| **Compute** | EC2 Instance | `t3.micro` instance running Docker on Amazon Linux 2023. |
| **Storage** | EBS Volume | Encrypted 30GB root volume (required for AL2023). |
| **Load Balancing** | Application Load Balancer | Distributes HTTP traffic (port 80) to the flask app (port 5000). |
| **Registry** | ECR Repository | Stores the Docker images for the application. |
| **Security** | IAM Roles & SGs | Least-privilege roles (ECR Pull, SSM) and strict security groups. |

---

## 🤝 How to Use This Infrastructure with the App

Once this infrastructure is deployed, it provides two key pieces of information needed for the Application repository:

### 1. ECR Repository URL
*   **What it is**: The address where you upload your Docker images.
*   **How to get it**: Run `terraform output ecr_repository_url`
*   **Usage**: In your Application CI/CD pipeline, you will build your Docker image and push it to this URL.
    *   Example: `123456789012.dkr.ecr.us-east-1.amazonaws.com/flask-challenge`

### 2. Application URL
*   **What it is**: The public DNS name of the Load Balancer.
*   **How to get it**: Run `terraform output alb_url`
*   **Usage**: This is the URL you share with users to access the running application.

### Integration Workflow
1.  **Infra Repo (This Repo)**: Deploys ECR + EC2 + ALB.
2.  **App Repo**: Builds Docker image → Pushes to ECR.
3.  **EC2 Instance**: Automatically pulls the latest image from ECR (via User Data script on boot, or manual restart).

---

## � Quick Start

### Prerequisites
- Terraform >= 1.9.0
- AWS CLI configured
- GitHub repository with OIDC configured

### Deployment Steps

1.  **Configure OIDC**: Ensure `AWS_ROLE_ARN` secret is set in GitHub Settings.
2.  **Push to Main**:
    ```bash
    git push origin main
    ```
    This triggers the CI/CD pipeline: `Quality -> Plan -> Approval -> Apply`.
3.  **Approve**: Go to GitHub Actions, review the plan, and approve the deployment.

### Cleanup
To avoid using up your credits:
```bash
terraform destroy
```

---

## � Security Features
- **No SSH**: Access via AWS SSM Session Manager only.
- **OIDC Auth**: GitHub Actions uses temporary credentials, no long-lived access keys.
- **Encrypted Storage**: EBS volumes are encrypted by default.
- **Strict Networking**: EC2 accepts traffic ONLY from the Load Balancer.

## 💰 Cost Estimates
- **EC2 (t3.micro)**: Covered by Free Tier (first 12 months) or ~$0.0104/hour.
- **ALB**: ~$0.0225/hour + capacity units. (Main cost driver - destroy when not in use!)
- **EBS (30GB)**: ~$2.40/month.


