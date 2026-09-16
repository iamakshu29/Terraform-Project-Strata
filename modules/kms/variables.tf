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

variable "kms_key" {
  type = object({
    deletion_window_in_days = number
    enable_key_rotation     = bool
  })
}