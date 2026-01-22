# Security Group Module
# Highly customizable security group for any AWS resource (EC2, ALB, RDS, etc.)

#------------------------------------------------------------------------------
# Security Group
#------------------------------------------------------------------------------
resource "aws_security_group" "this" {
  name        = "${var.name}-sg"
  description = var.description != null ? var.description : "Security group for ${var.name}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

#------------------------------------------------------------------------------
# Ingress Rules
#------------------------------------------------------------------------------
resource "aws_security_group_rule" "ingress" {
  for_each = { for idx, rule in var.ingress_rules : "${rule.from_port}-${rule.to_port}-${rule.protocol}" => rule }

  security_group_id = aws_security_group.this.id
  type              = "ingress"

  from_port   = each.value.from_port
  to_port     = each.value.to_port
  protocol    = each.value.protocol
  description = lookup(each.value, "description", null)

  # Support multiple source types (only one should be set)
  cidr_blocks              = lookup(each.value, "cidr_blocks", null)
  ipv6_cidr_blocks         = lookup(each.value, "ipv6_cidr_blocks", null)
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
  self                     = lookup(each.value, "self", null)
  prefix_list_ids          = lookup(each.value, "prefix_list_ids", null)
}

#------------------------------------------------------------------------------
# Egress Rules
#------------------------------------------------------------------------------
resource "aws_security_group_rule" "egress" {
  for_each = { for idx, rule in var.egress_rules : "${rule.from_port}-${rule.to_port}-${rule.protocol}" => rule }

  security_group_id = aws_security_group.this.id
  type              = "egress"

  from_port   = each.value.from_port
  to_port     = each.value.to_port
  protocol    = each.value.protocol
  description = lookup(each.value, "description", null)

  # Support multiple destination types (only one should be set)
  cidr_blocks              = lookup(each.value, "cidr_blocks", null)
  ipv6_cidr_blocks         = lookup(each.value, "ipv6_cidr_blocks", null)
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
  self                     = lookup(each.value, "self", null)
  prefix_list_ids          = lookup(each.value, "prefix_list_ids", null)
}
