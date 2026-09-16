# Single combined bucket policy for the logging bucket.
# Covers three writers: S3 server access logging, CloudTrail, and ALB access logs.
# Only one aws_s3_bucket_policy is allowed per bucket — multiple resources would silently overwrite each other.
data "aws_iam_policy_document" "strata_logging_bucket_policy" {
  # S3 server access logging
  statement {
    sid    = "AWSS3Logging"
    effect = "Allow"
    principals {
      identifiers = ["logging.s3.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["s3:PutObject", "s3:GetObject"]
    resources = ["${var.bucket_arns["strata-logging-bucket"]}/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  # CloudTrail ACL check
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [var.bucket_arns["strata-logging-bucket"]]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }

  # CloudTrail writes
  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${var.bucket_arns["strata-logging-bucket"]}/${var.cloudtrail.s3_key_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }

  # ALB log delivery (Standard AWS ELB Account for ap-south-1)
  statement {
    sid    = "AWSConsole-AccessLogs-Custom-Bucket"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.main.arn]
    }
    actions   = ["s3:PutObject"]
    resources = ["${var.bucket_arns["strata-logging-bucket"]}/alb-logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
  }

  # ALB log delivery - bucket permission (Log Delivery Service)
  statement {
    sid    = "ALBLogDeliveryAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [var.bucket_arns["strata-logging-bucket"]]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  #  ALB log delivery - object permission
  statement {
    sid    = "ALBLogDeliveryWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${var.bucket_arns["strata-logging-bucket"]}/alb-logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_s3_bucket_policy" "strata_logging_bucket" {
  bucket     = var.bucket_ids["strata-logging-bucket"]
  policy     = data.aws_iam_policy_document.strata_logging_bucket_policy.json
}

# Only configure access logging for non-logging buckets to avoid a circular loop.
# It will select the buckets which have logging = false
resource "aws_s3_bucket_logging" "strata_logging_config" {
  for_each = { for k, v in var.s3 : k => v if !v.logging }

  bucket        = var.bucket_ids[each.key]
  target_bucket = var.bucket_ids["strata-logging-bucket"]
  target_prefix = "log/"
  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}
