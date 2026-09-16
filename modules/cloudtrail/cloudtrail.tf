resource "aws_cloudtrail" "strata_trail" {
  name                          = var.cloudtrail.name
  s3_bucket_name                = var.logging_bucket_name
  s3_key_prefix                 = var.cloudtrail.s3_key_prefix
  include_global_service_events = var.cloudtrail.include_global_service_events

  # Bucket policy must exist before CloudTrail can write to it
}
