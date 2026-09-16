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

variable "security_group" {
  type = map(any)
}
