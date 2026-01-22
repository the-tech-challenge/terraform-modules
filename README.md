# Terraform AWS Modules 🏗️

A collection of **reusable, enterprise-grade Terraform modules** for provisioning AWS infrastructure. These modules are designed to be plug-and-play, making it easy for anyone to deploy secure, production-ready cloud resources.

---

## 📖 What is This Repository?

This repository contains **pre-built Terraform modules** that you can use like building blocks to create AWS infrastructure. Instead of writing hundreds of lines of Terraform code from scratch, you simply reference these modules and provide your configuration values.

**Think of it like LEGO blocks** 🧱 — each module is a pre-built piece (VPC, EC2, IAM Role, etc.), and you combine them to build your complete infrastructure.

---

## 📁 Available Modules

| Module | What It Creates | Use Case |
|--------|-----------------|----------|
| [**vpc**](./modules/vpc) | Virtual Private Cloud, subnets, internet gateway, route tables | Network foundation for your AWS resources |
| [**compute**](./modules/compute) | EC2 instances with security best practices | Running applications, web servers, containers |
| [**iam**](./modules/iam) | IAM roles, instance profiles, policies | Granting permissions to AWS resources |
| [**security-group**](./modules/security-group) | Security groups with flexible rules | Controlling network traffic (firewall rules) |

---

## 🚀 How to Use These Modules

### Prerequisites

Before using these modules, make sure you have:

1. **Terraform installed** (version 1.9.0 or higher)
   ```bash
   # Check your version
   terraform --version
   ```

2. **AWS Authentication via OIDC** (for CI/CD pipelines)
   
   This repository uses **OIDC (OpenID Connect)** for secure, keyless authentication with AWS. No access keys are stored in GitHub!

   **How it works:**
   ```
   GitHub Actions → OIDC Token → AWS IAM → Assume Role → Access AWS
   ```

   **Setup Steps:**
   1. Create an OIDC Identity Provider in AWS IAM for GitHub
   2. Create an IAM Role with a trust policy for your GitHub repo
   3. Add the role ARN as a secret `ROLE_TO_ASSUME` in your GitHub repository

   > 💡 **Why OIDC?** It's more secure than access keys because credentials are short-lived and automatically rotated.

### Step-by-Step Usage

#### Step 1: Create a New Terraform Project

Create a new folder for your infrastructure project:

```bash
mkdir my-infrastructure
cd my-infrastructure
```

#### Step 2: Create Your Main Configuration File

Create a file called `main.tf` and reference the modules you need:

```hcl
# Configure the AWS Provider
terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.70.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# ============================================
# STEP 1: Create a VPC (Your Network)
# ============================================
module "vpc" {
  source = "git::https://github.com/the-tech-challenge/terraform-modules.git//modules/vpc?ref=main"

  name               = "my-app"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]

  tags = {
    Environment = "dev"
    Project     = "my-project"
  }
}

# ============================================
# STEP 2: Create a Security Group (Firewall)
# ============================================
module "web_sg" {
  source = "git::https://github.com/the-tech-challenge/terraform-modules.git//modules/security-group?ref=main"

  name   = "web-server"
  vpc_id = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow HTTP from anywhere"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow HTTPS from anywhere"
    }
  ]

  tags = {
    Environment = "dev"
    Project     = "my-project"
  }
}

# ============================================
# STEP 3: Create an IAM Role (Permissions)
# ============================================
module "iam" {
  source = "git::https://github.com/the-tech-challenge/terraform-modules.git//modules/iam?ref=main"

  name             = "my-app"
  trusted_services = ["ec2.amazonaws.com"]
  enable_ssm       = true  # Allows SSH-less access via AWS Console

  tags = {
    Environment = "dev"
    Project     = "my-project"
  }
}

# ============================================
# STEP 4: Create an EC2 Instance (Server)
# ============================================
module "compute" {
  source = "git::https://github.com/the-tech-challenge/terraform-modules.git//modules/compute?ref=main"

  name                 = "my-app"
  instance_type        = "t3.micro"
  subnet_id            = module.vpc.public_subnet_ids[0]
  security_group_ids   = [module.web_sg.security_group_id]
  iam_instance_profile = module.iam.instance_profile_name

  tags = {
    Environment = "dev"
    Project     = "my-project"
  }
}

# ============================================
# OUTPUT: Important Information
# ============================================
output "server_public_ip" {
  description = "Public IP of your server"
  value       = module.compute.instance_public_ip
}

output "vpc_id" {
  description = "ID of your VPC"
  value       = module.vpc.vpc_id
}
```

#### Step 3: Deploy Your Infrastructure

Run these commands in order:

```bash
# 1. Initialize Terraform (downloads required modules)
terraform init

# 2. Preview what will be created
terraform plan

# 3. Create the infrastructure (requires confirmation)
terraform apply

# 4. When finished, destroy everything to avoid charges
terraform destroy
```

---

## 🔧 Module Reference Guide

### VPC Module

Creates your network foundation:

```hcl
module "vpc" {
  source = "git::https://github.com/the-tech-challenge/terraform-modules.git//modules/vpc?ref=main"

  name               = "my-app"           # Prefix for all resources
  vpc_cidr           = "10.0.0.0/16"      # IP range for your VPC
  availability_zones = ["us-east-1a", "us-east-1b"]  # Minimum 2 required
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]

  tags = {
    Environment = "dev"      # Required
    Project     = "my-app"   # Required
  }
}
```

**Outputs you can use:**
- `module.vpc.vpc_id` — VPC ID
- `module.vpc.public_subnet_ids` — List of subnet IDs

---

### Security Group Module

Creates firewall rules:

```hcl
module "my_sg" {
  source = "git::https://github.com/the-tech-challenge/terraform-modules.git//modules/security-group?ref=main"

  name   = "my-sg"
  vpc_id = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["YOUR.IP.ADDRESS/32"]  # Only your IP
      description = "SSH access"
    }
  ]

  tags = {
    Environment = "dev"
    Project     = "my-app"
  }
}
```

**Outputs you can use:**
- `module.my_sg.security_group_id` — Security Group ID

---

### IAM Module

Creates roles and permissions:

```hcl
module "iam" {
  source = "git::https://github.com/the-tech-challenge/terraform-modules.git//modules/iam?ref=main"

  name             = "my-role"
  trusted_services = ["ec2.amazonaws.com"]
  enable_ssm       = true                    # Connect without SSH
  enable_cloudwatch_logs = true              # Send logs to CloudWatch
  ecr_repository_arns = ["arn:aws:ecr:..."]  # Optional: ECR access

  tags = {
    Environment = "dev"
    Project     = "my-app"
  }
}
```

**Outputs you can use:**
- `module.iam.role_arn` — IAM Role ARN
- `module.iam.instance_profile_name` — For EC2 instances

---

### Compute Module

Creates EC2 instances:

```hcl
module "compute" {
  source = "git::https://github.com/the-tech-challenge/terraform-modules.git//modules/compute?ref=main"

  name                 = "my-server"
  instance_type        = "t3.micro"
  subnet_id            = module.vpc.public_subnet_ids[0]
  security_group_ids   = [module.my_sg.security_group_id]
  iam_instance_profile = module.iam.instance_profile_name

  # Optional: Run a script on startup
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker
    systemctl start docker
  EOF

  tags = {
    Environment = "dev"
    Project     = "my-app"
  }
}
```

**Outputs you can use:**
- `module.compute.instance_id` — EC2 Instance ID
- `module.compute.instance_public_ip` — Public IP address

---

## 🔄 How the CI/CD Pipeline Works

This repository has an **automated quality check system** that runs every time code changes are made. Here's how it works:

### When Does It Run?

The CI pipeline automatically triggers when:

| Event | Branches | Condition |
|-------|----------|-----------|
| **Push** (code committed) | `main`, `develop` | Only if files in `modules/` changed |
| **Pull Request** | `main`, `develop` | Only if files in `modules/` changed |

### What Does It Check?

```
┌─────────────────────────────────────────────────────────────────────┐
│                        CI PIPELINE FLOW                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   1. DETECT CHANGES                                                  │
│      ├── Scan which modules were modified                            │
│      └── Only run checks on changed modules (saves time!)            │
│                                                                      │
│   2. QUALITY CHECKS (for each changed module)                        │
│      ├── terraform fmt    → Code formatting check                    │
│      ├── terraform validate → Syntax/configuration validation        │
│      └── tflint           → Best practices & error detection         │
│                                                                      │
│   3. RESULT                                                          │
│      ├── ✅ All checks pass → Ready to merge!                        │
│      └── ❌ Any check fails → Fix issues before merging              │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Smart Change Detection

The pipeline is **smart** — it only runs checks on modules that have actually changed:

```
Example: You only modified modules/vpc/main.tf

Traditional CI: Would check ALL modules (slow)
Our CI:         Only checks the VPC module (fast!)
```

### Viewing CI Results

1. Go to the **Actions** tab in GitHub
2. Click on the latest workflow run
3. See the status of each check

### 🛡️ Adding Compliance Policies

You can extend the CI pipeline with **compliance policy checks** to ensure modules meet both internal and external standards:

| Tool | What It Checks |
|------|----------------|
| **Checkov** | CIS benchmarks, AWS best practices, HIPAA, SOC2 |
| **tfsec** | Security misconfigurations |
| **Custom Policies** | Your organization's internal standards |

**Example: Adding Compliance to CI**

```yaml
# In your workflow, add a compliance job
compliance-check:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    
    - name: Run Checkov
      uses: bridgecrewio/checkov-action@v12
      with:
        directory: modules/
        framework: terraform
        
    - name: Run Custom Policies
      run: |
        # Check for your internal standards
        checkov -d modules/ --external-checks-dir ./policies/
```

**Why Use Compliance Policies?**

- ✅ **External Standards** — Meet industry regulations (CIS, HIPAA, SOC2, PCI-DSS)
- ✅ **Internal Standards** — Enforce your organization's specific rules
- ✅ **Shift Left** — Catch compliance issues before deployment
- ✅ **Audit Trail** — Every check is recorded in CI history

---

## 🏷️ Mandatory Tagging

All modules **require** these tags to enforce organizational standards:

```hcl
tags = {
  Environment = "dev"       # dev, staging, prod
  Project     = "my-app"    # Your project name
}
```

These tags help with:
- **Cost tracking** — Know what's costing you money
- **Resource organization** — Find resources quickly
- **Compliance** — Meet organizational policies

---

## 🔒 Security Features Built-In

These modules include security best practices by default:

| Feature | Description |
|---------|-------------|
| **IMDSv2 Required** | Protects against SSRF attacks on EC2 |
| **Encrypted EBS Volumes** | Data at rest encryption |
| **SSM Session Manager** | No SSH keys needed (more secure) |
| **Minimal IAM Permissions** | Principle of least privilege |
| **Validated Inputs** | Prevents misconfigurations |

---

## ❓ Common Questions

### How do I update to a newer version of a module?

Change the `ref` parameter in your source URL:

```hcl
# Before (using main branch)
source = "git::https://github.com/.../modules/vpc?ref=main"

# After (using specific version)
source = "git::https://github.com/.../modules/vpc?ref=v1.2.0"
```

### How do I see what resources will be created?

Always run `terraform plan` before `terraform apply`:

```bash
terraform plan
```

### How do I destroy everything?

```bash
terraform destroy
```

### My deploy failed. What do I do?

1. Read the error message carefully
2. Check that your AWS credentials are valid
3. Verify your input values match the expected formats
4. Check the module's README for required inputs

---

## 📚 Additional Resources

- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform.io/cloud-docs/recommended-practices)

---

## 🤝 Contributing

1. Create a feature branch from `develop`
2. Make your changes in the appropriate module
3. Ensure all CI checks pass
4. Create a Pull Request to `develop`