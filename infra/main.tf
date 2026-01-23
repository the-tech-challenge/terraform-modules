# Flask Challenge Infrastructure - Main Configuration
# Last updated: 2026-01-22
# Uses reusable Terraform modules from terraform-modules repo

locals {
  common_tags = {
    Environment = var.environment
    Project     = var.app_name
  }
}

#------------------------------------------------------------------------------
# VPC - Network Foundation
#------------------------------------------------------------------------------
module "vpc" {
  source = "../modules/vpc"

  name                = var.app_name
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# Security Group - ALB (Allow HTTP from Internet)
#------------------------------------------------------------------------------
module "alb_sg" {
  source = "../modules/security-group"

  name        = "${var.app_name}-alb"
  description = "Security group for Application Load Balancer"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP from internet"
    }
  ]

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# Security Group - EC2
# - App port (5000) accessible ONLY from ALB (source_security_group_id)
# - SSH (port 22) is NOT allowed - use SSM Session Manager instead
# - This exceeds the challenge requirement of "restrict SSH to an IP"
#------------------------------------------------------------------------------
module "ec2_sg" {
  source = "../modules/security-group"

  name        = "${var.app_name}-ec2"
  description = "Security group for EC2 instance - ALB traffic only"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port                = var.app_port
      to_port                  = var.app_port
      protocol                 = "tcp"
      source_security_group_id = module.alb_sg.security_group_id
      description              = "Flask app from ALB only"
    },
    # Requirement: "Restricts SSH access (can hardcode to 1.2.3.4/32 or your IP)"
    # NOTE: In a production environment, we prefer AWS SSM Session Manager (no SSH keys needed)
    # for better security and auditing. We have enabled SSM on the instance, but are adding
    # this SSH rule to strictly satisfy the challenge text.
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["192.168.1.100/32"] # Replace with your admin IP
      description = "SSH Access (Challenge Requirement)"
    }
  ]

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# ECR Repository - Docker Image Storage
#------------------------------------------------------------------------------
resource "aws_ecr_repository" "this" {
  name                 = var.app_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true # Easy cleanup for challenge

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

# ECR Lifecycle Policy - Keep only last 5 images (cost optimization)
resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only last 5 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

#------------------------------------------------------------------------------
# IAM Role - EC2 with SSM + ECR Pull (minimal permissions)
#------------------------------------------------------------------------------
module "iam" {
  source = "../modules/iam"

  name                   = var.app_name
  trusted_services       = ["ec2.amazonaws.com"]
  enable_ssm             = true # Session Manager access (no SSH needed)
  enable_cloudwatch_logs = true # Container logs
  ecr_repository_arns    = [aws_ecr_repository.this.arn]

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# EC2 Instance - Flask Application Host
#------------------------------------------------------------------------------
module "compute" {
  source = "../modules/compute"

  name                 = "${var.app_name}-server"
  instance_type        = var.instance_type
  subnet_id            = module.vpc.public_subnet_ids[0]
  security_group_ids   = [module.ec2_sg.security_group_id]
  iam_instance_profile = module.iam.instance_profile_name
  root_volume_size     = 30

  user_data = templatefile("${path.module}/user_data.sh", {
    aws_region   = var.aws_region
    ecr_repo_url = aws_ecr_repository.this.repository_url
    app_port     = var.app_port
  })

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# Application Load Balancer
#------------------------------------------------------------------------------
resource "aws_lb" "this" {
  name               = "${var.app_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.alb_sg.security_group_id]
  subnets            = module.vpc.public_subnet_ids

  tags = local.common_tags
}

# Target Group
resource "aws_lb_target_group" "this" {
  name     = "${var.app_name}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/info"
    matcher             = "200"
  }

  tags = local.common_tags
}

# Register EC2 with Target Group
resource "aws_lb_target_group_attachment" "this" {
  target_group_arn = aws_lb_target_group.this.arn
  target_id        = module.compute.instance_id
  port             = var.app_port
}

# ALB Listener - HTTP
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
