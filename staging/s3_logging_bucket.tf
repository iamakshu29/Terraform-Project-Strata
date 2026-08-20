# Single combined bucket policy for the logging bucket.
# Covers three writers: S3 server access logging, CloudTrail, and ALB access logs.
# Only one aws_s3_bucket_policy is allowed per bucket — multiple resources would silently overwrite each other.
data "aws_iam_policy_document" "strata_logging_bucket_policy" {
  statement {
    sid    = "AWSS3Logging"
    effect = "Allow"
    principals {
      identifiers = ["logging.s3.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["s3:PutObject", "s3:GetObject"]
    resources = ["${aws_s3_bucket.strata_bucket["strata_logging_bucket"].arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.strata_bucket["strata_logging_bucket"].arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.strata_bucket["strata_logging_bucket"].arn}/${var.cloudtrail.s3_key_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }

  statement {
    sid    = "ALBLogDeliveryAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.strata_bucket["strata_logging_bucket"].arn]
  }

  statement {
    sid    = "ALBLogDelivery"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.strata_bucket["strata_logging_bucket"].arn}/alb-logs/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "strata_logging_bucket" {
  bucket     = aws_s3_bucket.strata_bucket["strata_logging_bucket"].id
  policy     = data.aws_iam_policy_document.strata_logging_bucket_policy.json
  depends_on = [aws_s3_bucket_public_access_block.strata_bucket_access_block]
}

# Only configure access logging for non-logging buckets to avoid a circular loop.
resource "aws_s3_bucket_logging" "strata_logging_config" {
  for_each = { for k, v in var.s3 : k => v if !v.logging }

  bucket        = aws_s3_bucket.strata_bucket[each.key].id
  target_bucket = aws_s3_bucket.strata_bucket["strata_logging_bucket"].id
  target_prefix = "log/"
  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}