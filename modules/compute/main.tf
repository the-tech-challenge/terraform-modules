# Compute Module - v1.0.0
# Creates EC2 instance (security group managed separately via security-group module)

#------------------------------------------------------------------------------
# Data: Amazon Linux 2023 AMI
# n-1 versioning: AL2023 is the stable choice (AL2 EOL June 2026)
#------------------------------------------------------------------------------
data "aws_ami" "amazon_linux" {
  count = var.ami_id == null ? 1 : 0

  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  ami_id = var.ami_id != null ? var.ami_id : data.aws_ami.amazon_linux[0].id
}

#------------------------------------------------------------------------------
# EC2 Instance
#------------------------------------------------------------------------------
resource "aws_instance" "this" {
  ami                    = local.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  iam_instance_profile   = var.iam_instance_profile
  key_name               = var.key_name

  user_data                   = var.user_data
  user_data_replace_on_change = true

  # IMDSv2 required (security best practice)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
    http_put_response_hop_limit = 2
  }

  # Root volume
  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}
