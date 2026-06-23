variable "aws_region" {
  type        = string
  description = "Region Name"
  default     = "ap-south-1"
}

variable "env_tag" {
  type        = string
  description = "Environment Value"
  default     = "dev"
}

variable "vpc" {
  type        = object({ cidr = string })
  description = "This is a correct CIDR which will not work as AWS, Always use terraform.tfvars"
}

# ----------------------------------------------------------------------

# ALB, NAT GW, Bastion
variable "public_subnets" {
  type = map(object({
    cidr = string
    az   = string
  }))
  description = "Configuration map for public subnets indexed by availability zone keys"
}

# ECS Fargate, ASG/EC2
variable "private_subnets" {
  type = map(object({
    cidr = string
    az   = string
  }))
  description = "Configuration map for private subnets indexed by availability zone keys"
}

# RDS, ElastiCache
variable "data_subnets" {
  type = map(object({
    cidr = string
    az   = string
  }))
  description = "Configuration map for data subnets indexed by availability zone keys"
}

# ----------------------------------------------------------------------

variable "nat_gateway_azs" {
  type        = list(string)
  description = "Containes AZ to create NAT GW"
}

# ingress:
#   allow TCP 80  from VPC CIDR
#   allow TCP 443 from VPC CIDR

# egress:
#   allow TCP destination ports 1024-65535 to anywhere
variable "public_nacl_rules" {
  type = object({
    ingress = map(object({
      protocol   = string
      rule_no    = number
      action     = string
      from_port  = number
      to_port    = number
      cidr_block = string
    }))

    egress = map(object({
      protocol   = string
      rule_no    = number
      action     = string
      from_port  = number
      to_port    = number
      cidr_block = string
    }))
  })
  description = "Public NACL Attributes"
}

variable "private_nacl_rules" {
  type = object({
    ingress = map(object({
      protocol   = string
      rule_no    = number
      action     = string
      from_port  = number
      to_port    = number
      cidr_block = string
    }))

    egress = map(object({
      protocol   = string
      rule_no    = number
      action     = string
      from_port  = number
      to_port    = number
      cidr_block = string
    }))
  })
  description = "Private NACL Attributes"
}

variable "data_nacl_rules" {
  type = object({
    ingress = map(object({
      protocol   = string
      rule_no    = number
      action     = string
      from_port  = number
      to_port    = number
      cidr_block = string
    }))

    egress = map(object({
      protocol   = string
      rule_no    = number
      action     = string
      from_port  = number
      to_port    = number
      cidr_block = string
    }))
  })
  description = "Data NACL Attributes"
}

variable "nacl_subnet_association" {
  type    = map(any)
  default = {}
}

# ----------------------------------------------------------------------

variable "cloudwatch" {
  type    = map(number)
  default = {}
}

# ----------------------------------------------------------------------

variable "route" {
  type = object({
    public_routes = map(object({
      destination_cidr = string
    }))

    private_routes = map(object({
      destination_cidr = string
    }))

    data_routes = map(object({
      destination_cidr = string
    }))
  })

  description = "Defining Public, Private and Data Routes"
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
  description = "RDS values"
}

# ----------------------------------------------------------------------


variable "kms_key" {
  type = object({
    deletion_window_in_days = number
    enable_key_rotation     = bool
  })
}

# ----------------------------------------------------------------------
variable "secrets" {
  type        = map(string)
  description = "RDS username and password"
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
  type = map(map(object({
    sid       = string
    effect    = string
    actions   = list(string)
    resources = list(string)
  })))
}

variable "assume_role_policy" {
  type = map(object({
    Version           = string
    Action            = string
    Effect            = string
    Sid               = string
    Principal_Service = string
  }))
}

variable "role_names" {
  type = object({
    ec2_role_key          = string
    ecs_role_key          = string
    vpc_flow_log_role_key = string
  })
}

# ----------------------------------------------------------------------

variable "s3" {
  type = map(object({
    block_public_acls       = bool
    block_public_policy     = bool
    ignore_public_acls      = bool
    restrict_public_buckets = bool
    versioning_status       = string
    IA_transition_days      = number
    glacier_transiton_days  = number
    delete_data_after       = number
  }))
}

variable "s3_logging" {

}

variable "metrics" {
  type = map(any)
}