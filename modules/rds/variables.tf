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

variable "rds" {
  type = object({
    allocated_storage          = number
    auto_minor_version_upgrade = bool
    backup_retention_period    = number
    identifier                 = string
    multi_az                   = bool
    publicly_accessible        = bool
    deletion_protection        = bool
    storage_encrypted          = bool
    skip_final_snapshot        = bool
    apply_immediately          = bool
    instance_class             = string
    engine_version             = string
    engine                     = string
    db_name                    = string
  })
  description = "RDS values"
}