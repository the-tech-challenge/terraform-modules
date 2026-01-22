variable "name" {
  description = "Name prefix for the security group"
  type        = string

  validation {
    condition     = length(var.name) >= 2 && length(var.name) <= 32
    error_message = "Name must be between 2 and 32 characters."
  }

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.name))
    error_message = "Name must start with a letter and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "description" {
  description = "Description for the security group"
  type        = string
  default     = null

  validation {
    condition     = var.description == null || length(var.description) <= 255
    error_message = "Description must be 255 characters or less."
  }
}

variable "vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-f0-9]+$", var.vpc_id))
    error_message = "VPC ID must be a valid AWS VPC ID (vpc-xxxxxxxxx)."
  }
}

variable "ingress_rules" {
  description = "List of ingress rules"
  type = list(object({
    from_port                = number
    to_port                  = number
    protocol                 = string
    description              = optional(string)
    cidr_blocks              = optional(list(string))
    ipv6_cidr_blocks         = optional(list(string))
    source_security_group_id = optional(string)
    self                     = optional(bool)
    prefix_list_ids          = optional(list(string))
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.ingress_rules :
      rule.from_port >= 0 && rule.from_port <= 65535
    ])
    error_message = "Ingress rule from_port must be between 0 and 65535."
  }

  validation {
    condition = alltrue([
      for rule in var.ingress_rules :
      rule.to_port >= 0 && rule.to_port <= 65535
    ])
    error_message = "Ingress rule to_port must be between 0 and 65535."
  }

  validation {
    condition = alltrue([
      for rule in var.ingress_rules :
      contains(["tcp", "udp", "icmp", "-1"], rule.protocol)
    ])
    error_message = "Ingress rule protocol must be tcp, udp, icmp, or -1 (all)."
  }
}

variable "egress_rules" {
  description = "List of egress rules (defaults to allow all outbound)"
  type = list(object({
    from_port                = number
    to_port                  = number
    protocol                 = string
    description              = optional(string)
    cidr_blocks              = optional(list(string))
    ipv6_cidr_blocks         = optional(list(string))
    source_security_group_id = optional(string)
    self                     = optional(bool)
    prefix_list_ids          = optional(list(string))
  }))
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound traffic"
    }
  ]
}

variable "tags" {
  description = "Tags to apply to the security group (must include required tags)"
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
