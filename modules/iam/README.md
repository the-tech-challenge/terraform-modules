# IAM Module

![Version](https://img.shields.io/badge/version-1.0.0-blue)

Provisions IAM roles and instance profiles with minimal permissions following the principle of least privilege.

## Features

- ✅ IAM role with configurable trust policy
- ✅ Instance profile for EC2 attachment
- ✅ SSM Session Manager support (no SSH keys needed)
- ✅ CloudWatch Logs integration
- ✅ ECR pull permissions (minimal - only what's needed)
- ✅ Custom policy support
- ✅ Additional managed policy attachment
- ✅ Input validation for ARNs and service principals
- ✅ Mandatory tagging enforcement

## Usage

### Basic EC2 Role with SSM and ECR

```hcl
module "iam" {
  source = "path/to/modules/iam"

  name                = "flask-app"
  trusted_services    = ["ec2.amazonaws.com"]
  enable_ssm          = true
  enable_cloudwatch_logs = true
  ecr_repository_arns = [aws_ecr_repository.app.arn]

  tags = {
    Environment = "dev"
    Project     = "flask-challenge"
  }
}

# Use in compute module
module "compute" {
  source = "path/to/modules/compute"
  # ...
  iam_instance_profile = module.iam.instance_profile_name
}
```

### With Custom Policy

```hcl
module "iam" {
  source = "path/to/modules/iam"

  name             = "custom-app"
  trusted_services = ["ec2.amazonaws.com"]

  custom_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = ["arn:aws:s3:::my-bucket/*"]
      }
    ]
  })

  tags = {
    Environment = "dev"
    Project     = "custom-project"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.0, < 2.0.0 |
| aws | >= 5.70.0, < 6.0.0 |

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| name | Name prefix for IAM resources | string | yes |
| trusted_services | AWS service principals | list(string) | no (default: ec2.amazonaws.com) |
| create_instance_profile | Create EC2 instance profile | bool | no (default: true) |
| enable_ssm | Attach SSM policy | bool | no (default: true) |
| enable_cloudwatch_logs | Attach CloudWatch policy | bool | no (default: true) |
| ecr_repository_arns | ECR repos for pull access | list(string) | no |
| custom_policy_json | Custom IAM policy JSON | string | no |
| additional_policy_arns | Additional managed policy ARNs | list(string) | no |
| tags | Resource tags (must include Environment, Project) | map(string) | yes |

## Outputs

| Name | Description |
|------|-------------|
| role_arn | IAM role ARN |
| role_name | IAM role name |
| instance_profile_arn | Instance profile ARN |
| instance_profile_name | Instance profile name |

## Security Considerations

- SSM is enabled by default (replaces need for SSH)
- ECR permissions are minimal (only pull, not push)
- CloudWatch Logs uses FullAccess - consider restricting in production
- Use `custom_policy_json` with least privilege principle
- Avoid using `additional_policy_arns` with broad permissions
