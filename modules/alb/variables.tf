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

variable "lb" {
  type = map(any)
}

variable "target_group" {
  type = map(any)
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the load balancer target groups"
}

variable "security_group_ids" {
  type        = map(string)
  description = "Security group IDs keyed by security group name"
}

variable "public_subnet_ids" {
  type        = map(string)
  description = "Public subnet IDs keyed by availability zone"
}

variable "logging_bucket_name" {
  type        = string
  description = "S3 bucket name for ALB access logs"
}
