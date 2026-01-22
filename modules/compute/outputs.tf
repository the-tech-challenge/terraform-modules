output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.this.id
}

output "instance_public_ip" {
  description = "Public IP address"
  value       = aws_instance.this.public_ip
}

output "instance_private_ip" {
  description = "Private IP address"
  value       = aws_instance.this.private_ip
}

output "ami_id" {
  description = "AMI ID used"
  value       = local.ami_id
}
