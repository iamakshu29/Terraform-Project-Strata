resource "aws_cloudtrail" "strata_trail" {
  name                          = var.cloudtrail.name
  s3_bucket_name                = aws_s3_bucket.strata_bucket["strata-logging-bucket"].id
  s3_key_prefix                 = var.cloudtrail.s3_key_prefix
  include_global_service_events = var.cloudtrail.include_global_service_events

  # Bucket policy must exist before CloudTrail can write to it
  depends_on = [aws_s3_bucket_policy.strata_logging_bucket]
}
