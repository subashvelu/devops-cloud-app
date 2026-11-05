output "alb_dns_name" {
  description = "Public URL of the Application Load Balancer (open this in your browser)"
  value       = "http://${aws_lb.main.dns_name}"
}

output "ecr_repository_url" {
  description = "Full ECR repository URL"
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_repository_name" {
  description = "Use this value for the GitHub secret ECR_REPOSITORY"
  value       = aws_ecr_repository.app.name
}

output "instance_id" {
  description = "Use this value for the GitHub secret EC2_INSTANCE_ID"
  value       = aws_instance.app_host.id
}

output "aws_region" {
  description = "Use this value for the GitHub secret AWS_REGION"
  value       = var.aws_region
}
