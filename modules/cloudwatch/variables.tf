variable "aws_region" {
  type        = string
  description = "Region Name"
  default     = "ap-south-1"
}

variable "cloudwatch" {
  type    = map(number)
  default = {}
}