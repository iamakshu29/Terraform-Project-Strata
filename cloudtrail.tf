locals {
  trail_arn = "arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:trail/${var.cloudtrail.name}"
}

resource "aws_cloudtrail" "strata_trail" {
  name                          = var.cloudtrail.name
  s3_bucket_name                = aws_s3_bucket.strata_bucket["strata_logging_bucket"].id
  s3_key_prefix                 = var.cloudtrail.s3_key_prefix
  include_global_service_events = var.cloudtrail.include_global_service_events

  depends_on = [aws_s3_bucket_policy.strata_cloudtrail_bucket_policy]
}

data "aws_iam_policy_document" "strata_cloudtrail_bucket_policy" {
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
}

resource "aws_s3_bucket_policy" "strata_cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.strata_bucket["strata_logging_bucket"].id
  policy = data.aws_iam_policy_document.strata_cloudtrail_bucket_policy.json
}