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

variable "route" {
  type = object({
    public_routes = map(object({
      destination_cidr = string
    }))
  })

  description = "Public route table entries only — private and data routes are derived from subnet maps"
}

variable "acm_domain_validation_options" {
  type    = any
  default = []
}

variable "alb_dns_name" {
  type = string
}

variable "alb_zone_id" {
  type = string
}