variable "aws_region" {
  type        = string
  description = "Region Name"
  default     = "ap-south-1"
}

variable "aws_bastian_instance" {
  type = map(any)
}

