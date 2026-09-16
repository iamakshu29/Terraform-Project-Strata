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

# variable "route_table" {

# }

# variable "route_table_association" {

# }

# ----------------------------------------------------------------------

variable "security_group" {
  type = map(any)
}

variable "route" {
  type = object({
    public_routes = map(object({
      destination_cidr = string
    }))
  })
}