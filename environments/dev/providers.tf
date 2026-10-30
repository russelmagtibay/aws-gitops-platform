terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Saves Dev state into its own folder inside your Phase 1 S3 bucket
  backend "s3" {
    bucket       = "aws-gitops-platform-tfstate-570515227299"
    key          = "environments/dev/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  # Automatically stamps these 3 tags onto every resource in all 6 modules
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "dev"
      ManagedBy   = "Terraform-GitOps"
    }
  }
}