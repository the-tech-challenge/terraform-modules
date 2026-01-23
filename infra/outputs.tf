# Outputs - Important values for CI/CD and access

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer - use this to access the app"
  value       = aws_lb.this.dns_name
}

output "alb_url" {
  description = "Full URL to access the application"
  value       = "http://${aws_lb.this.dns_name}"
}

output "ecr_repository_url" {
  description = "ECR repository URL for Docker push"
  value       = aws_ecr_repository.this.repository_url
}

output "ecr_repository_name" {
  description = "ECR repository name"
  value       = aws_ecr_repository.this.name
}

output "ec2_instance_id" {
  description = "EC2 instance ID (for SSM access and deployments)"
  value       = module.compute.instance_id
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "info_endpoint" {
  description = "Full URL to the /info endpoint"
  value       = "http://${aws_lb.this.dns_name}/info"
}
