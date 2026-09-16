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
    ecs_task_role_key     = string
    vpc_flow_log_role_key = string
  })
}
