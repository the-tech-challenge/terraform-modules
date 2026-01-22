variable "name" {
  description = "Name prefix for IAM resources"
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

variable "trusted_services" {
  description = "AWS services that can assume this role"
  type        = list(string)
  default     = ["ec2.amazonaws.com"]

  validation {
    condition     = length(var.trusted_services) >= 1
    error_message = "At least one trusted service is required."
  }

  validation {
    condition = alltrue([
      for service in var.trusted_services :
      can(regex("^[a-z0-9-]+\\.amazonaws\\.com$", service))
    ])
    error_message = "Trusted services must be valid AWS service principals (e.g., ec2.amazonaws.com)."
  }
}

variable "create_instance_profile" {
  description = "Create an instance profile for EC2"
  type        = bool
  default     = true
}

variable "enable_ssm" {
  description = "Attach SSM managed instance core policy (for Session Manager)"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_logs" {
  description = "Attach CloudWatch logs policy"
  type        = bool
  default     = true
}

variable "ecr_repository_arns" {
  description = "ECR repository ARNs for pull access"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for arn in var.ecr_repository_arns :
      can(regex("^arn:aws:ecr:[a-z0-9-]+:[0-9]+:repository/.+$", arn))
    ])
    error_message = "ECR repository ARNs must be valid (arn:aws:ecr:region:account:repository/name)."
  }
}

variable "custom_policy_json" {
  description = "Custom IAM policy JSON document"
  type        = string
  default     = null

  validation {
    condition     = var.custom_policy_json == null || can(jsondecode(var.custom_policy_json))
    error_message = "Custom policy must be valid JSON."
  }
}

variable "additional_policy_arns" {
  description = "Additional managed policy ARNs to attach"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for arn in var.additional_policy_arns :
      can(regex("^arn:aws:iam::(aws|[0-9]+):policy/.+$", arn))
    ])
    error_message = "Policy ARNs must be valid IAM policy ARNs."
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
