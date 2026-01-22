# IAM Module - v1.0.0
# Creates IAM role and instance profile for EC2 with minimal permissions

#------------------------------------------------------------------------------
# IAM Role
#------------------------------------------------------------------------------
resource "aws_iam_role" "this" {
  name = "${var.name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = var.trusted_services
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.name}-role"
  })
}

#------------------------------------------------------------------------------
# Instance Profile (for EC2)
#------------------------------------------------------------------------------
resource "aws_iam_instance_profile" "this" {
  count = var.create_instance_profile ? 1 : 0

  name = "${var.name}-instance-profile"
  role = aws_iam_role.this.name

  tags = var.tags
}

#------------------------------------------------------------------------------
# SSM Managed Instance Core (for Session Manager - no SSH keys needed)
#------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "ssm" {
  count = var.enable_ssm ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

#------------------------------------------------------------------------------
# CloudWatch Logs
#------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

#------------------------------------------------------------------------------
# ECR Pull Policy (minimal - only what's needed to pull images)
#------------------------------------------------------------------------------
resource "aws_iam_role_policy" "ecr_pull" {
  count = length(var.ecr_repository_arns) > 0 ? 1 : 0

  name = "${var.name}-ecr-pull"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ECRGetAuthToken"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "ECRPullImages"
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
        Resource = var.ecr_repository_arns
      }
    ]
  })
}

#------------------------------------------------------------------------------
# Custom Policy (optional)
#------------------------------------------------------------------------------
resource "aws_iam_role_policy" "custom" {
  count = var.custom_policy_json != null ? 1 : 0

  name   = "${var.name}-custom"
  role   = aws_iam_role.this.id
  policy = var.custom_policy_json
}

#------------------------------------------------------------------------------
# Additional Managed Policies
#------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "additional" {
  count = length(var.additional_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = var.additional_policy_arns[count.index]
}
