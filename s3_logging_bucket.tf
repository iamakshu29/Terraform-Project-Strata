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
}

resource "aws_s3_bucket_policy" "logging" {
  bucket = aws_s3_bucket.strata_bucket["strata_logging_bucket"].id
  policy = data.aws_iam_policy_document.strata_logging_bucket_policy.json
}

# Only configure access logging for non-logging buckets (logging = false)
# to avoid a circular logging loop on the logging bucket itself.
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