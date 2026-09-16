module "acm" {
  source = "../modules/acm"

  environment = "dev"
}

module "alb" {
  source = "../modules/alb"

  environment = "dev"
}

module "asg" {
  source = "../modules/asg"

  environment = "dev"
}

module "bastian" {
  source = "../modules/bastian"

  environment = "dev"
}

module "cloudtrail" {
  source = "../modules/cloudtrail"

  environment = "dev"
}

module "cloudwatch" {
  source = "../modules/cloudwatch"


  environment = "dev"
}

module "ecr" {
  source = "../modules/ecr"

  environment = "dev"
}

module "ecs" {
  source = "../modules/ecs"

  environment = "dev"
}

module "elasticache_redis" {
  source = "../modules/elasticache_redis"

  environment = "dev"
}

module "iam" {
  source = "../modules/iam"

  environment = "dev"
}

module "kms" {
  source = "../modules/kms"

  environment = "dev"
}

module "rds" {
  source = "../modules/rds"

  environment = "dev"
}

module "route53" {
  source = "../modules/route53"

  environment = "dev"
}

module "s3" {
  source = "../modules/s3"

  environment = "dev"
}

module "s3_logging" {
  source = "../modules/s3_logging"

  environment = "dev"
}

module "secrets_manager" {
  source = "../modules/secrets_manager"

  environment = "dev"
}

module "security_group" {
  source = "../modules/security_group"

  environment = "dev"
}

module "ssm_parameter_store" {
  source = "../modules/ssm_parameter_store"

  environment = "dev"
}

module "vpc" {
  source = "../modules/vpc"

  vpc_cidr    = "10.10.0.0/16"
  environment = "dev"
}
