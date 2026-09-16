module "vpc" {
  source = "../../modules/vpc"

  env_tag            = var.env_tag
  vpc                = var.vpc
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  data_subnets       = var.data_subnets
  nat_gateway_azs    = var.nat_gateway_azs
  public_nacl_rules  = var.public_nacl_rules
  private_nacl_rules = var.private_nacl_rules
  data_nacl_rules    = var.data_nacl_rules
  security_group     = var.security_group
  route              = var.route
}

module "security_group" {
  source = "../../modules/security_group"

  env_tag        = var.env_tag
  vpc_id         = module.vpc.vpc_id
  security_group = var.security_group
}

module "iam" {
  source = "../../modules/iam"

  env_tag            = var.env_tag
  iam_policy         = var.iam_policy
  assume_role_policy = var.assume_role_policy
  role_names         = var.role_names
}

module "kms" {
  source = "../../modules/kms"

  env_tag = var.env_tag
  kms_key = var.kms_key
}

module "acm" {
  source = "../../modules/acm"

  env_tag     = var.env_tag
  domain_name = var.domain_name
}

module "s3" {
  source = "../../modules/s3"

  env_tag     = var.env_tag
  s3          = var.s3
  role_arns   = module.iam.role_arns
  role_names  = var.role_names
  kms_key_arn = module.kms.key_arn
}

module "s3_logging" {
  source = "../../modules/s3_logging"

  env_tag      = var.env_tag
  s3           = var.s3
  bucket_ids   = module.s3.bucket_ids
  bucket_arns  = { for key, name in module.s3.bucket_names : key => "arn:aws:s3:::${name}" }
  bucket_names = module.s3.bucket_names
  cloudtrail   = var.cloudtrail
}

module "alb" {
  source = "../../modules/alb"

  env_tag            = var.env_tag
  vpc_id             = module.vpc.vpc_id
  security_group_ids = module.security_group.security_group_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  logging_bucket_name = module.s3_logging.logging_bucket_name
  lb                 = var.lb
  target_group       = var.target_group
}

module "rds" {
  source = "../../modules/rds"

  env_tag              = var.env_tag
  rds                  = var.rds
  db_credentials       = var.secrets
  security_group_id    = module.security_group.security_group_ids["rds"]
  db_subnet_group_name = module.vpc.db_subnet_group_name
  kms_key_arn          = module.kms.key_arn
}

module "elasticache_redis" {
  source = "../../modules/elasticache_redis"

  env_tag           = var.env_tag
  elasticache       = var.elasticache
  data_subnet_ids   = module.vpc.data_subnet_ids
  security_group_id = module.security_group.security_group_ids["redis"]
  kms_key_arn       = module.kms.key_arn
}

module "secrets_manager" {
  source = "../../modules/secrets_manager"

  env_tag     = var.env_tag
  secrets     = var.secrets
  kms_key_arn = module.kms.key_arn
}

module "ecr" {
  source = "../../modules/ecr"

  kms_key_arn = module.kms.key_arn
}

module "cloudtrail" {
  source = "../../modules/cloudtrail"

  cloudtrail          = var.cloudtrail
  logging_bucket_name = module.s3.bucket_names["strata-logging-bucket"]
}

module "cloudwatch" {
  source = "../../modules/cloudwatch"

  env_tag           = var.env_tag
  cloudwatch        = var.cloudwatch
  metrics           = var.metrics
  vpc_id            = module.vpc.vpc_id
  flow_log_role_arn = module.iam.role_arns[var.role_names.vpc_flow_log_role_key]
  dimension_value_to_arn = {
    "lb-arn_suffix"            = module.alb.alb_arn_suffix
    "lb-target_group"          = module.alb.target_group_arn_suffix
    "rds_identifier"           = var.rds.identifier
    "elasticache_rep_group_id" = var.elasticache.replication_group_id
  }
}

module "asg" {
  source = "../../modules/asg"

  env_tag            = var.env_tag
  launch_template    = var.launch_template
  asg                = var.asg
  assume_role_policy = var.assume_role_policy
  role_names         = var.role_names
  iam_policy         = var.iam_policy
  ec2_role_name      = module.iam.role_names[var.role_names.ec2_role_key]
  security_group_id  = module.security_group.security_group_ids["ec2"]
  kms_key_arn        = module.kms.key_arn
  private_subnet_ids = module.vpc.private_subnet_ids
  target_group_arn   = module.alb.target_group_arns["strataInstance"]
  resource_label     = "${module.alb.alb_arn_suffix}/${module.alb.target_group_arn_suffix}"
}

module "bastian" {
  source = "../../modules/bastian"

  env_tag              = var.env_tag
  aws_bastian_instance = var.aws_bastian_instance
  subnet_id             = module.vpc.public_subnet_ids[var.aws_bastian_instance.subnet_az]
  security_group_id     = module.security_group.security_group_ids["bastion"]
  iam_instance_profile_name = module.iam.role_names[var.role_names.ec2_role_key]
  kms_key_arn           = module.kms.key_arn
}

module "ecs" {
  source = "../../modules/ecs"

  env_tag            = var.env_tag
  assume_role_policy = var.assume_role_policy
  ecs_cluster        = var.ecs_cluster
  task_definitions   = var.task_definitions
  service_discovery  = var.service_discovery
  ecs_service        = var.ecs_service
  private_subnets    = var.private_subnets
  iam_policy         = var.iam_policy
  role_names         = var.role_names
  efs                = var.efs
  kms_key_arn        = module.kms.key_arn
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_ids = module.security_group.security_group_ids
  role_arns          = module.iam.role_arns
  target_group_arns  = module.alb.target_group_arns
  service_log_group_name = "/ecs/strata"
  alarm_names         = []
}

module "route53" {
  source = "../../modules/route53"

  env_tag                       = var.env_tag
  domain_name                   = var.domain_name
  route                         = var.route
  acm_domain_validation_options = module.acm.domain_validation_options
  alb_dns_name                  = module.alb.alb_dns_name
  alb_zone_id                   = module.alb.alb_zone_id
}

module "ssm_parameter_store" {
  source = "../../modules/ssm_parameter_store"

  env_tag = var.env_tag
  parameter_values = {
    "/strata/app/db/endpoint"       = module.rds.rds_endpoint
    "/strata/app/s3/bucket"         = module.s3.bucket_names["strata-bucket"]
    "/strata/app/s3_logging/bucket" = module.s3.bucket_names["strata-logging-bucket"]
    "/strata/app/redis/primary"     = module.elasticache_redis.redis_primary_endpoint
    "/strata/app/redis/reader"      = module.elasticache_redis.redis_reader_endpoint
    "/strata/app/service/endpoint"  = module.alb.alb_dns_name
  }
  kms_key_arn = module.kms.key_arn
}
