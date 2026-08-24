terraform {
  required_version = ">= 1.10.0, < 2.0.0" # terraform version

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.46" # provder version
    }
  }

  # Pass -backend-config="key=strata/dev/terraform.tfstate" (or prod) at init time
  backend "s3" {
    bucket       = "strata-tfstate-025066281843"
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