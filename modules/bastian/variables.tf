variable "aws_region" {
  type        = string
  description = "Region Name"
  default     = "ap-south-1"
}

variable "aws_bastian_instance" {
  type = map(any)
}

variable "env_tag" {
  type    = string
  default = "dev"
}

variable "subnet_id" { type = string }
variable "security_group_id" { type = string }
variable "iam_instance_profile_name" { type = string }
variable "kms_key_arn" { type = string }

