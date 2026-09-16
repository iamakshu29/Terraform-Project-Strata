terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.46"
    }
  }
  # State for this bootstrap config stays local — it only manages one bucket
}

provider "aws" {
  region  = "ap-south-1"
  profile = "strata"
}
