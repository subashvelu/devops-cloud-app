variable "aws_region" {
  description = "AWS region for resources (ap-south-1 = Mumbai)"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Prefix for created resources"
  type        = string
  default     = "devops-cloud-app"
}

variable "instance_type" {
  description = "EC2 instance size"
  type        = string
  default     = "t3.micro"
}

variable "environment" {
  description = "Environment tag (dev, staging, production)"
  type        = string
  default     = "dev"
}
