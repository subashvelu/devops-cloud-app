terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # ---------------------------------------------------------------------------
  # OPTIONAL: remote state.
  # By default Terraform keeps its "memory" (terraform.tfstate) in a local file.
  # If that file is lost, Terraform forgets what it created. For real projects,
  # store it in S3. Create an S3 bucket by hand first, then uncomment:
  #
  # backend "s3" {
  #   bucket       = "YOUR-UNIQUE-BUCKET-NAME"
  #   key          = "devops-cloud-app/terraform.tfstate"
  #   region       = "ap-south-1"
  #   use_lockfile = true # state locking (needs Terraform >= 1.10)
  #   encrypt      = true
  # }
  # ---------------------------------------------------------------------------
}

provider "aws" {
  region = var.aws_region

  # These tags are automatically added to every resource that supports tags.
  default_tags {
    tags = {
      Project     = "DevOps-Cloud-App"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}
