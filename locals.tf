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

  dimension_value_to_arn = {
    "lb-arn_suffix"            = aws_lb.strata["strataLB"].arn_suffix
    "rds_identifier"           = var.rds.identifier
    "elasticache_rep_group_id" = var.elasticache.replication_group_id
    "ecs_cluster"              = aws_ecs_cluster.strata_cluster.name
    "ecs_service"              = aws_ecs_service.strata_service.name
    "lb-target_group"          = aws_lb_target_group.strata["strataInstance"].arn_suffix
  }

  trail_arn = "arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:trail/${var.cloudtrail.name}"

}
