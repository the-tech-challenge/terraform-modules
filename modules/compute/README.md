# Compute Module

![Version](https://img.shields.io/badge/version-1.0.0-blue)

Provisions a secure EC2 instance with enterprise-grade defaults including IMDSv2, encrypted EBS, and AL2023.

## Features

- ✅ Amazon Linux 2023 AMI (n-1 versioning for 2026)
- ✅ IMDSv2 required (security best practice)
- ✅ Encrypted root EBS volume (gp3)
- ✅ User data support for Docker bootstrap
- ✅ External security group attachment
- ✅ Input validation for AWS resource IDs
- ✅ Mandatory tagging enforcement

## Usage

```hcl
module "compute" {
  source = "path/to/modules/compute"

  name               = "flask-app"
  subnet_id          = module.vpc.public_subnet_ids[0]
  security_group_ids = [module.ec2_sg.security_group_id]
  iam_instance_profile = module.iam.instance_profile_name
  instance_type      = "t3.micro"

  user_data = templatefile("${path.module}/user_data.sh", {
    ecr_repo_url = aws_ecr_repository.app.repository_url
    aws_region   = var.aws_region
  })

  tags = {
    Environment = "dev"
    Project     = "flask-challenge"
  }
}
```

## User Data Example (Docker Bootstrap)

```bash
#!/bin/bash
yum update -y
yum install -y docker
systemctl enable docker
systemctl start docker

# Login to ECR and run container
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${ecr_repo_url}
docker pull ${ecr_repo_url}:latest
docker run -d -p 5000:5000 ${ecr_repo_url}:latest
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.0, < 2.0.0 |
| aws | >= 5.70.0, < 6.0.0 |

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| name | Instance name | string | yes |
| subnet_id | Subnet ID (valid subnet-xxx format) | string | yes |
| security_group_ids | List of SG IDs (valid sg-xxx format) | list(string) | yes |
| instance_type | EC2 instance type | string | no (default: t3.micro) |
| ami_id | AMI ID (default: Amazon Linux 2023) | string | no |
| iam_instance_profile | IAM instance profile name | string | no |
| key_name | SSH key pair name | string | no |
| user_data | Bootstrap script (max 16KB) | string | no |
| root_volume_size | Root volume GB (8-16384) | number | no (default: 8) |
| tags | Resource tags (must include Environment, Project) | map(string) | yes |

## Outputs

| Name | Description |
|------|-------------|
| instance_id | EC2 instance ID |
| instance_public_ip | Public IP address |
| instance_private_ip | Private IP address |
| ami_id | AMI ID used |

## Security Considerations

- IMDSv2 is required (hop limit: 2 for containerized workloads)
- Root volume is encrypted by default
- SSH key is optional - prefer SSM Session Manager for access
- Security groups must be provided externally for separation of concerns
