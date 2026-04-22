terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }

  # Remote state — stores terraform.tfstate in S3 so the team shares state
  # and DynamoDB prevents two people running terraform apply at the same time.
  #
  # ⚠️  BEFORE RUNNING: create this S3 bucket and DynamoDB table manually
  #     (see README Step 2 — Bootstrap)
  backend "s3" {
    bucket         = "devops-demo-terraform-state"   # ← Change to your bucket name
    key            = "infra/terraform.tfstate"
    region         = "ap-south-1"                    # ← Change to your region
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  # Tags applied to every resource created by Terraform
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Repo        = "github.com/YOUR_USERNAME/aws-terraform-infrastructure"
    }
  }
}
