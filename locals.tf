locals {
  vpc_cidr = var.vpc.cidr

  tags = {
    Project     = "Strata"
    Environment = var.env_tag
  }

  # ap-south-1c shares the 1b NAT GW — only 2 NAT GWs provisioned to save cost
  az_to_nat = {
    "ap-south-1a" = "ap-south-1a"
    "ap-south-1b" = "ap-south-1b"
    "ap-south-1c" = "ap-south-1b"
  }

  dimension_value_to_arn = {
    "lb-arn_suffix"            = aws_lb.strata["strataLB"].arn_suffix
    "rds_identifier"           = var.rds.identifier
    "elasticache_rep_group_id" = var.elasticache.replication_group_id
    "ecs_cluster"              = var.ecs_cluster["strata_cluster"].name
    "ecs_service"              = var.ecs_service["strata_service"].name
    "lb-target_group"          = aws_lb_target_group.strata["strataInstance"].arn_suffix
  }

  trail_arn = "arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:trail/${var.cloudtrail.name}"

  state_bucket_name = "strata-tfstate-${data.aws_caller_identity.current.account_id}"

  subnet_map = {
    public  = aws_subnet.strata_public_subnet
    private = aws_subnet.strata_private_subnet
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

  # SSM parameter paths keyed by env — used in aws_ssm_parameter for_each
  parameters = {
    "/${var.env_tag}/app/db/endpoint"       = aws_db_instance.strata_db.endpoint
    "/${var.env_tag}/app/s3/bucket"         = aws_s3_bucket.strata_bucket["strata_bucket"].bucket
    "/${var.env_tag}/app/s3_logging/bucket" = aws_s3_bucket.strata_bucket["strata_logging_bucket"].bucket
    "/${var.env_tag}/app/redis/primary"     = aws_elasticache_replication_group.strata_redis.primary_endpoint_address
    "/${var.env_tag}/app/redis/reader"      = aws_elasticache_replication_group.strata_redis.reader_endpoint_address
    "/${var.env_tag}/app/service/endpoint"  = aws_lb.strata["strataLB"].dns_name
  }

  # Flattens var.iam_policy into a single map keyed by "role-policy" for for_each
  policies = merge([
    for role_name, policy in var.iam_policy : {
      for policy_name, policy_element in policy :
      "${role_name}-${policy_name}" => {
        role_name       = role_name
        policy_name     = policy_name
        policy_elements = policy_element
      }
    }
  ]...)

  ingress_rules = merge([
    for sg_name, sg in var.security_group : {
      for rule_name, rule in sg.ingress :
      "${sg_name}-${rule_name}" => {
        sg_name = sg_name
        rule    = rule
      }
    }
  ]...)
}
