# VPC Module

![Version](https://img.shields.io/badge/version-1.0.0-blue)

Provisions a production-ready VPC with public and optional private subnets across multiple availability zones.

## Features

- ✅ Multi-AZ deployment (minimum 2 AZs for ALB compatibility)
- ✅ Public subnets with Internet Gateway
- ✅ Optional private subnets
- ✅ Route tables with proper associations
- ✅ DNS hostnames and support enabled
- ✅ Mandatory tagging enforcement

## Usage

```hcl
module "vpc" {
  source = "path/to/modules/vpc"

  name               = "my-app"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]

  tags = {
    Environment = "dev"
    Project     = "my-project"
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
| name | Name prefix for resources | string | yes |
| vpc_cidr | CIDR block for VPC | string | no (default: 10.0.0.0/16) |
| availability_zones | List of AZs (min 2) | list(string) | yes |
| public_subnet_cidrs | CIDR blocks for public subnets | list(string) | yes |
| private_subnet_cidrs | CIDR blocks for private subnets | list(string) | no |
| tags | Resource tags (must include Environment, Project) | map(string) | yes |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | VPC ID |
| vpc_cidr_block | VPC CIDR block |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |
| internet_gateway_id | Internet Gateway ID |

## Security Considerations

- This module creates public subnets with `map_public_ip_on_launch = true`
- For production, consider using private subnets with NAT Gateway
- No NAT Gateway included (cost optimization for dev/staging)
