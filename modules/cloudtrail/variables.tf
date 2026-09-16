variable "aws_region" {
  type        = string
  description = "Region Name"
  default     = "ap-south-1"
}

variable "cloudtrail" {
  type = object({
    name                          = string
    s3_key_prefix                 = string
    include_global_service_events = bool
  })
}