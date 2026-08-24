terraform {
  required_version = ">= 1.10.0, < 2.0.0" # terraform version

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.46" # provder version
    }
  }

  # After running `cd bootstrap && terraform apply`, copy the state_bucket_name output here.
  # Then run: terraform init -migrate-state
  # use_lockfile = true enables S3 native locking (Terraform >= 1.10, no DynamoDB needed)
  backend "s3" {
    bucket       = "strata-tfstate-025066281843"
    key          = "strata/dev/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
    profile      = "strata"
  }
}

provider "aws" {
  region = var.aws_region
  profile = "strata"
}