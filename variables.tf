variable "aws_region" {
  type = string
  default = "us-east-1"
}

variable "env_tag" {
  type        = string
  description = "Environment Value"
  default     = "dev"
}

variable "vpc" {
  type        = map(any)
  description = "This is a correct CIDR which will not work as AWS, Always use terraform.tfvars"
}

# ALB, NAT GW, Bastion
variable "public_subnets" {
  type        = map(any)
  description = "CIDRs for public subnet"
}

# ECS Fargate, ASG/EC2
variable "private_subnets" {
  type        = map(any)
  description = "CIDRs for private subnet"
}

# RDS, ElastiCache
variable "data_subnets" {
  type        = map(any)
  description = "CIDRs for data subnet"
}

variable "nat_gateway_azs" {
  type        = list(string)
  description = "used to create nat and eip allocation"
}

# ingress:
#   allow TCP 80  from VPC CIDR
#   allow TCP 443 from VPC CIDR

# egress:
#   allow TCP destination ports 1024-65535 to anywhere
variable "public_nacl_rules" {
  type        = map(any)
  description = "Public NACL Attributes"
}

variable "private_nacl_rules" {
  type        = map(any)
  description = "Private NACL Attributes"
}

variable "data_nacl_rules" {
  type        = map(any)
  description = "Data NACL Attributes"
}

variable "nacl_subnet_association" {
  type    = map(any)
  default = {}
}

# variable "cloudwatch" {

# }

# variable "vpc_flow_logs" {

# }

# ----------------------------------------------------------------------

variable "route" {

}

# variable "route_table" {

# }

# variable "route_table_association" {

# }

# ----------------------------------------------------------------------

variable "security_group" {
  type = map(any)
}

# ----------------------------------------------------------------------------
variable "rds" {
  type = object({
    allocated_storage          = number
    auto_minor_version_upgrade = bool
    backup_retention_period    = number
    identifier                 = string
    multi_az                   = bool
    publicly_accessible        = bool
    deletion_protection        = bool
    storage_encrypted          = bool
    skip_final_snapshot        = bool
    apply_immediately          = bool
    instance_class             = string
    engine_version             = string
    engine                     = string
    db_name                    = string
  })
}

variable "kms_key" {
  type = object({
    deletion_window_in_days = number
    enable_key_rotation     = bool
  })
}

# ----------------------------------------------------------------------
variable "secrets" {
  type = map(string)

  default = {
    key1 = "value1"
    key2 = "value2"
  }
}

# ----------------------------------------------------------------------
variable "aws_bastian_instance" {
  type = map(any)
}

variable "launch_template" {
  type = map(any)
}

variable "asg" {
  type = map(any)
}

# ----------------------------------------------------------------------

variable "iam_policy" {

}

# variable "iam_role" {

# }
