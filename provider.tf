terraform {
  required_version = ">= 1.9.0, < 2.0.0" # terraform version

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.46" # provder version
    }
  }

  # Uncomment after running `terraform apply` once to create the state bucket.
  # Then run: terraform init -migrate-state
  # use_lockfile = true enables S3 native locking (Terraform >= 1.10, no DynamoDB needed)
  #
  # backend "s3" {
  #   bucket       = "<value from state_bucket_name output>"
  #   key          = "strata/dev/terraform.tfstate"
  #   region       = "ap-south-1"
  #   encrypt      = true
  #   use_lockfile = true
  # }
}

provider "aws" {
  region = var.aws_region
}