# Security Group Module

Provisions a highly customizable AWS Security Group with flexible ingress and egress rules.

## Features

- ✅ Flexible ingress/egress rule definitions
- ✅ Support for CIDR blocks, security group sources, self-references
- ✅ Support for prefix list IDs
- ✅ Input validation for ports and protocols
- ✅ Mandatory tagging enforcement
- ✅ Lifecycle management (create_before_destroy)

## Usage

### ALB Security Group (HTTP from Internet)

```hcl
module "alb_sg" {
  source = "path/to/modules/security-group"

  name   = "alb"
  vpc_id = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP from internet"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS from internet"
    }
  ]

  tags = {
    Environment = "dev"
    Project     = "my-project"
  }
}
```

### EC2 Security Group (Only from ALB)

```hcl
module "ec2_sg" {
  source = "path/to/modules/security-group"

  name   = "ec2"
  vpc_id = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port                = 5000
      to_port                  = 5000
      protocol                 = "tcp"
      source_security_group_id = module.alb_sg.security_group_id
      description              = "Flask app from ALB only"
    }
  ]

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
| name | Name prefix for security group | string | yes |
| description | Security group description | string | no |
| vpc_id | VPC ID (must be valid vpc-xxx format) | string | yes |
| ingress_rules | List of ingress rules | list(object) | no |
| egress_rules | List of egress rules (default: allow all) | list(object) | no |
| tags | Resource tags (must include Environment, Project) | map(string) | yes |

## Outputs

| Name | Description |
|------|-------------|
| security_group_id | ID of the security group |
| security_group_arn | ARN of the security group |
| security_group_name | Name of the security group |

## Security Considerations

- Default egress allows all outbound traffic (0.0.0.0/0)
- For production, consider restricting egress to specific destinations
- Use `source_security_group_id` instead of CIDR blocks when possible
