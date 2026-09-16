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

variable "s3" {
  type = map(object({
    block_public_acls              = bool
    block_public_policy            = bool
    ignore_public_acls             = bool
    restrict_public_buckets        = bool
    rule_id                        = string
    versioning_status              = string
    status                         = string
    first_transition_storage_type  = string
    first_transition_storage_days  = number
    second_transition_storage_type = string
    second_transiton_storage_days  = number
    delete_data_after              = number
    logging                        = bool
  }))
}

variable "role_arns" {
  type        = map(string)
  description = "IAM role ARNs keyed by role name"
}

variable "role_names" {
  type = object({
    ec2_role_key          = string
    ecs_role_key          = string
    ecs_task_role_key     = string
    vpc_flow_log_role_key = string
  })
}

variable "kms_key_arn" {
  type = string
}