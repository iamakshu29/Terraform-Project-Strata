variable "aws_region" {
  type        = string
  description = "Region Name"
  default     = "ap-south-1"
}

variable "cloudwatch" {
  type    = map(number)
  default = {}
}

variable "env_tag" {
  type    = string
  default = "dev"
}

variable "vpc_id" {
  type = string
}

variable "flow_log_role_arn" {
  type = string
}

variable "dimension_value_to_arn" {
  type    = map(string)
  default = {}
}

variable "metrics" {
  type    = map(any)
  default = {}
}