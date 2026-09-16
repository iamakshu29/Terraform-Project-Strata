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

# ECS Fargate, ASG/EC2
variable "private_subnets" {
  type = map(object({
    cidr = string
    az   = string
  }))
  description = "Configuration map for private subnets indexed by availability zone keys"
}

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
    ecs_task_role_key     = string
    vpc_flow_log_role_key = string
  })
}

variable "efs" {

}

variable "ecs_cluster" {

}

variable "service_discovery" {
  type = map(any)
}

variable "ecs_service" {
  type = map(any)
}

variable "task_definitions" {
  type = map(any)
}

variable "kms_key_arn" {
  type = string
}

variable "private_subnet_ids" {
  type = map(string)
}

variable "security_group_ids" {
  type = map(string)
}

variable "role_arns" {
  type = map(string)
}

variable "target_group_arns" {
  type    = map(string)
  default = {}
}

variable "service_log_group_name" {
  type    = string
  default = "/ecs/strata"
}

variable "alarm_names" {
  type    = list(string)
  default = []
}