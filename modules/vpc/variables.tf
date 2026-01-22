variable "name" {
  description = "Name prefix for all resources"
  type        = string

  validation {
    condition     = length(var.name) >= 3 && length(var.name) <= 32
    error_message = "Name must be between 3 and 32 characters."
  }

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.name))
    error_message = "Name must start with a letter and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }

  validation {
    condition     = tonumber(split("/", var.vpc_cidr)[1]) >= 16 && tonumber(split("/", var.vpc_cidr)[1]) <= 24
    error_message = "VPC CIDR must have a prefix between /16 and /24."
  }
}

variable "availability_zones" {
  description = "List of availability zones (minimum 2 for ALB)"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones are required for ALB high availability."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (must match AZ count)"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "At least 2 public subnets are required for ALB."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (optional)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources (must include required tags)"
  type        = map(string)
  default     = {}

  validation {
    condition     = contains(keys(var.tags), "Environment") || contains(keys(var.tags), "environment")
    error_message = "Tags must include 'Environment' (e.g., dev, staging, prod)."
  }

  validation {
    condition     = contains(keys(var.tags), "Project") || contains(keys(var.tags), "project")
    error_message = "Tags must include 'Project' for cost allocation."
  }
}
