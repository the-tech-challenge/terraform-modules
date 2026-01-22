variable "name" {
  description = "Name for the instance and resources"
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

variable "subnet_id" {
  description = "Subnet ID for the instance"
  type        = string

  validation {
    condition     = can(regex("^subnet-[a-f0-9]+$", var.subnet_id))
    error_message = "Subnet ID must be a valid AWS subnet ID (subnet-xxxxxxxxx)."
  }
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to the instance"
  type        = list(string)

  validation {
    condition     = length(var.security_group_ids) >= 1
    error_message = "At least one security group ID is required."
  }

  validation {
    condition = alltrue([
      for sg_id in var.security_group_ids :
      can(regex("^sg-[a-f0-9]+$", sg_id))
    ])
    error_message = "All security group IDs must be valid AWS security group IDs (sg-xxxxxxxxx)."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]*\\.[a-z0-9]+$", var.instance_type))
    error_message = "Instance type must be a valid AWS instance type format (e.g., t3.micro, m5.large)."
  }
}

variable "ami_id" {
  description = "AMI ID (defaults to latest Amazon Linux 2023)"
  type        = string
  default     = null

  validation {
    condition     = var.ami_id == null || can(regex("^ami-[a-f0-9]+$", var.ami_id))
    error_message = "AMI ID must be a valid AWS AMI ID (ami-xxxxxxxxx)."
  }
}

variable "iam_instance_profile" {
  description = "IAM instance profile name"
  type        = string
  default     = null
}

variable "key_name" {
  description = "SSH key pair name (optional - use SSM instead)"
  type        = string
  default     = null
}

variable "user_data" {
  description = "User data script for instance initialization"
  type        = string
  default     = ""

  validation {
    condition     = length(var.user_data) <= 16384
    error_message = "User data cannot exceed 16KB."
  }
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 8

  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 16384
    error_message = "Root volume size must be between 8 GB and 16384 GB."
  }
}

variable "tags" {
  description = "Tags to apply to resources (must include required tags)"
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
