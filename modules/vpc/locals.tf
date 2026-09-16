locals {
  vpc_cidr = var.vpc.cidr

  tags = {
    Project     = "Strata"
    Environment = var.env_tag
  }

  az_to_nat = {
    for az in keys(var.private_subnets) : az => contains(var.nat_gateway_azs, az) ? az : var.nat_gateway_azs[0]
  }

  interface_endpoints = {
    ecr_api        = "com.amazonaws.${var.aws_region}.ecr.api"
    ecr_dkr        = "com.amazonaws.${var.aws_region}.ecr.dkr"
    secretsmanager = "com.amazonaws.${var.aws_region}.secretsmanager"
    ssm            = "com.amazonaws.${var.aws_region}.ssm"
    ssmmessages    = "com.amazonaws.${var.aws_region}.ssmmessages"
    ec2messages    = "com.amazonaws.${var.aws_region}.ec2messages"
    logs           = "com.amazonaws.${var.aws_region}.logs"
    kms            = "com.amazonaws.${var.aws_region}.kms"
  }
}
