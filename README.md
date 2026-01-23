# Terraform Enterprise Modules & Infrastructure 🏗️

This repository serves a dual purpose:
1.  **Modules Library (`modules/`)**: A collection of reusable, enterprise-grade Terraform modules.
2.  **Infrastructure Implementation (`infra/`)**: A reference implementation utilizing these modules to deploy a Flask application.

---

## 📂 Project Structure

```text
.
├── modules/               # 📦 The "Building Blocks"
│   ├── vpc/               #    - Networking module
│   ├── compute/           #    - EC2 module
│   └── ...
│
└── infra/                 # 🏗️ The "House" (Implementation)
    ├── main.tf            #    - Combines modules to build the solution
    ├── providers.tf       #    - AWS & Backend config
    └── ...
```

---

## 🚀 Getting Started (For New Users)

If you are forking or setting this up in your own environment, you **MUST** complete these one-time manual steps before the pipelines will work.

### 1. Create Remote Backend (S3 + DynamoDB)

**Why?**
- **S3 Bucket**: Stores the `terraform.tfstate` file centrally so everyone on the team sees the same infrastructure state.
- **DynamoDB Table** (Optional but Recommended): "Locks" the state during updates to prevent two people/pipelines from modifying infra at the same time.

**Action:**
You can do this manually in the console or by running a script.

**Option A: Manual Setup**
1.  Log into AWS Console.
2.  **Create S3 Bucket**:
    - Name: `tech-challenge-tfstate-<YOUR_ACCOUNT_ID>` (must be globally unique)
    - Region: `us-east-1`
    - Settings: Block Public Access (Enabled), Versioning (Enabled).
3.  **Create DynamoDB Table** (Optional):
    - Name: `tech-challenge-tflock-<YOUR_ACCOUNT_ID>`
    - Partition Key: `LockID` (String)
4.  **Update Config**:
    - Open `infra/providers.tf` and check the `backend "s3"` block. Update bucket and table names. If skipping DynamoDB, remove the `dynamodb_table` line.

**Option B: Scripted Setup**
If you have a backend bootstrap script, you can run it to verify/provision these resources automatically.

### 2. Set Up AWS Authentication

**REQUIRED: OIDC (OpenID Connect)**
**Note:** To use the CI/CD pipelines in this repository **as-is**, you **must** configure OIDC. The workflows are pre-configured to use it.

**Why?** It's more secure. GitHub Actions creates a temporary token to access AWS. No long-lived secrets are stored.

**Setup:**
1.  **Create Identity Provider**:
    - Go to IAM > Identity providers > Add provider > OpenID Connect.
    - Provider URL: `https://token.actions.githubusercontent.com`
    - Audience: `sts.amazonaws.com`
2.  **Create IAM Role**:
    - Trusted Entity: Web Identity.
    - Policy: `AdministratorAccess` (or scoped down).
    - **Trust Policy**:
      ```json
      {
          "Version": "2012-10-17",
          "Statement": [
              {
                  "Effect": "Allow",
                  "Principal": {
                      "Federated": "arn:aws:iam::<YOUR_ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
                  },
                  "Action": "sts:AssumeRoleWithWebIdentity",
                  "Condition": {
                      "StringEquals": {
                          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                      },
                      "StringLike": {
                          "token.actions.githubusercontent.com:sub": "repo:<YOUR_GITHUB_ORG>/<YOUR_REPO_NAME>:*"
                      }
                  }
              }
          ]
      }
      ```
3.  **Add Secret to GitHub**:
    - Create New Secret: `AWS_ROLE_ARN` with your Role ARN.

**Alternative: AWS Access Keys (Standard)**
If you cannot configure OIDC, you can use standard AWS keys.

**Setup:**
1.  Create an IAM User with programmatic access.
2.  Add the following secrets to GitHub:
    - `AWS_ACCESS_KEY_ID`
    - `AWS_SECRET_ACCESS_KEY`
3.  **Update Workflow**: You will need to modify `.github/workflows/infra-ci.yml` `aws-actions/configure-aws-credentials` step to use these keys instead of `role-to-assume`.

---

## 🔄 CI/CD Automation Explained

We have two distinct automated pipelines that run depending on **what** you change.

### Scenario A: You modify a Module (`modules/**`)

If you edit code inside `modules/vpc`, `modules/compute`, etc.

**Pipeline Triggered**: `.github/workflows/ci.yml`

**What Happens:**
1.  **Smart Detection**: The pipeline checks *exactly* which modules changed.
2.  **Quality Matrix**: It spins up parallel jobs for *only* the changed modules.
3.  **Checks Run**:
    - `terraform fmt`: Ensures code is pretty.
    - `terraform validate`: Checks for syntax errors.
    - `tflint`: Scans for best practices and deprecated usage.
    - `terraform init`: Verifies providers can be downloaded.

**Result**: Ensures your "building blocks" (modules) are solid before anyone uses them.

### Scenario B: You modify Infrastructure (`infra/**`)

If you edit `infra/main.tf` or any file in the `infra/` folder.

**Pipeline Triggered**: `.github/workflows/infra-ci.yml`

**What Happens:**
1.  **Authentication**: Authenticates via OIDC using the `AWS_ROLE_ARN`.
2.  **Quality Check**: Runs fmt/validate/tflint on the implementation code.
3.  **Terraform Plan**:
    - Runs `terraform plan`.
    - Shows you exactly what resources will be created/modified/deleted.
    - **Outcome**: A reviewable plan in the GitHub Action logs.
4.  **Terraform Apply** (Only on `main` branch push):
    - **Environment Protection**: This job targets the `production` environment, which requires **Manual Approval** in the GitHub UI before proceeding.
    - **Automatically Deploys** the changes to your AWS account after approval.
    - Uses the State Bucket to make sure it's updating the existing environment.

---

## 🛠️ Usage Guide

### Using Modules in Your Own Code

Reference the modules locally or via Git:

```hcl
module "vpc" {
  # Local reference (if in same repo)
  source = "../modules/vpc"

  # Git reference (if using from another repo)
  # source = "git::https://github.com/the-tech-challenge/terraform-modules.git//modules/vpc?ref=main"

  name     = "my-app"
  vpc_cidr = "10.0.0.0/16"
  # ...
}
```

### Running the Infra Locally

1.  **Configure Credentials**:
    ```bash
    export AWS_PROFILE=default  # Or set AWS_ACCESS_KEY_ID/SECRET
    ```
2.  **Navigate & Init**:
    ```bash
    cd infra
    terraform init
    ```
3.  **Plan & Apply**:
    ```bash
    terraform plan
    terraform apply
    ```

---

## 🏷️ Standards & Best Practices

- **Mandatory Tagging**: All resources must have `Environment` and `Project` tags.
- **Security Group Rules**: Modules enforce strict rules (e.g., SSH only via SSM, no open 0.0.0.0/0 for management ports).
- **IMDSv2 Support**:
    - We have enabled **IMDSv2** support but set it to `optional` to ensure compatibility with the provided legacy application (which likely uses IMDSv1).
    - **Recommendation**: In a real production deployment, we would enforce `http_tokens = "required"` for maximum security against SSRF, but we have relaxed this for the challenge to ensure the app works out-of-the-box.
- **Versioning**: We recommend pinning module versions (using `?ref=v1.0.0`) in production to avoid surprise breaking changes.