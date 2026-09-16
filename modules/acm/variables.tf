variable "aws_region" {
  type        = string
  description = "Region Name"
  default     = "ap-south-1"
}

variable "domain_name" {
  type        = string
  description = "Public domain name used for the ACM certificate (e.g. strata.example.com)"
}

variable "env_tag" {
  type        = string
  description = "Environment Value"
  default     = "dev"
}