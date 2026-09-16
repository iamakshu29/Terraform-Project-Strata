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

variable "route" {
  type = object({
    public_routes = map(object({
      destination_cidr = string
    }))
  })

  description = "Public route table entries only — private and data routes are derived from subnet maps"
}