locals {
  vpc_cidr = var.vpc.cidr

  tags = {
    Project     = "Strata"
    Environment = var.env_tag
  }

  # For creating route as per nat available in azs
  az_to_nat = {
    "ap-south-1a" = "ap-south-1a"
    "ap-south-1b" = "ap-south-1b"
    "ap-south-1c" = "ap-south-1b" # as I create NAT in only 2 regions
  }

}