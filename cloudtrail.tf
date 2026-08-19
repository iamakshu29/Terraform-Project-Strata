locals {
  trail_arn = "arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:trail/${var.cloudtrail.name}"
}

resource "aws_cloudtrail" "strata_trail" {
  name                          = var.cloudtrail.name
  s3_bucket_name                = aws_s3_bucket.strata_bucket["strata_logging_bucket"].id
  s3_key_prefix                 = var.cloudtrail.s3_key_prefix
  include_global_service_events = var.cloudtrail.include_global_service_events

  # Bucket policy must exist before CloudTrail can write to it
  depends_on = [aws_s3_bucket_policy.strata_logging_bucket]
}