terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  # Production S3 backend template (configured during init)
  # backend "s3" {
  #   bucket         = "saas-platform-terraform-state-prod"
  #   key            = "platform/ecs/terraform.tfstate"
  #   region         = "us-west-2"
  #   dynamodb_table = "saas-platform-terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "Production SaaS Platform"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Repository  = "terraform-aws-production-saas-blueprint"
      Compliance  = "NIST-800-53-SOC2-HITRUST-CIS"
    }
  }
}
