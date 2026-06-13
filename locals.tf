locals {
  vpc_cidr = var.vpc.cidr

  tags = {
    Project     = "Strata"
    Environment = var.env_tag
  }

  # For creating route as per nat available in azs
  az_to_nat = {
    "us-east-1a" = "us-east-1a"
    "us-east-1b" = "us-east-1b"
    "us-east-1c" = "us-east-1b" # as I create NAT in only 2 regions
  }

  db_subnet_group_name = [for s in aws_subnet.strata_data_subnet : s.id]

}