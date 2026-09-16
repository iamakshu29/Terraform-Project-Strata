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

variable "elasticache" {
  type = object({
    replication_group_id     = string
    description              = string
    node_type                = string
    num_cache_clusters       = number
    port                     = number
    parameter_group_name     = string
    maintenance_window       = string
    snapshot_retention_limit = number
    snapshot_window          = string
    apply_immediately        = bool
  })
  description = "ElastiCache Redis replication group configuration"
}

variable "data_subnet_ids" {
  type = map(string)
}

variable "security_group_id" {
  type = string
}

variable "kms_key_arn" {
  type = string
}