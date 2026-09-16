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

variable "parameter_values" {
  type    = map(string)
  default = {}
}

variable "kms_key_arn" {
  type = string
}