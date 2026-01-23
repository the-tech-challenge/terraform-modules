# AWS Provider Configuration
# Credentials should be supplied via:
# - Environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
# - AWS CLI profile
# - OIDC (for GitHub Actions)

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70.0"
    }
  }

  # Backend - Static Configuration (Manual Setup)
  backend "s3" {
    bucket         = "tech-challenge-tfstate-140352704144"
    key            = "flask-challenge/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tech-challenge-tflock-140352704144"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.app_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
