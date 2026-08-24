data "aws_caller_identity" "current" {}

locals {
  bucket_name = "strata-tfstate-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket" "strata_state" {
  bucket = local.bucket_name

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name    = "strata-terraform-state"
    Project = "Strata"
  }
}

resource "aws_s3_bucket_versioning" "strata_state" {
  bucket = aws_s3_bucket.strata_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "strata_state" {
  bucket = aws_s3_bucket.strata_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Uses AWS-managed key — no dependency on the main project's KMS key
resource "aws_s3_bucket_server_side_encryption_configuration" "strata_state" {
  bucket = aws_s3_bucket.strata_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}
