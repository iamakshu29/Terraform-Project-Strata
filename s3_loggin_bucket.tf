data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "strata_logging_bucket" {
  bucket = "strata-logging-bucket"
  tags   = local.tags
}

data "aws_iam_policy_document" "strata_logging_bucket_policy" {
  statement {
    principals {
      identifiers = ["logging.s3.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["s3:PutObject", "s3:GetObject"]
    resources = ["${aws_s3_bucket.strata_logging_bucket.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_s3_bucket_policy" "logging" {
  bucket = aws_s3_bucket.strata_logging_bucket.bucket
  policy = data.aws_iam_policy_document.strata_logging_bucket_policy.json
}

resource "aws_s3_bucket_logging" "strata_logging_config" {
  bucket = aws_s3_bucket.strata_bucket.bucket

  target_bucket = aws_s3_bucket.strata_logging_bucket.bucket
  target_prefix = "log/"
  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}