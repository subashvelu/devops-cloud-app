output "ecr_repository_url" {
  description = "ECR image repository URL"
  value       = aws_ecr_repository.app.repository_url
}

output "alb_dns_name" {
  description = "Public URL of Application Load Balancer"
  value       = "http://${aws_lb.main.dns_name}"
}

output "instance_id" {
  description = "EC2 Instance ID for SSM deployment"
  value       = aws_instance.app_host.id
}
