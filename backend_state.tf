#   1. Apply THIS file first with the local backend (default).
#   2. Add S3 bucket in provider.tf and fill in the bucket name from the output below.
#   3. Run `terraform init -migrate-state` to move local state into S3.

resource "aws_s3_bucket" "strata_state" {
  bucket = local.state_bucket_name

  lifecycle {
    prevent_destroy = true
  }

  tags = merge({ Name = "strata-terraform-state" }, local.tags)
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

resource "aws_s3_bucket_server_side_encryption_configuration" "strata_state" {
  bucket = aws_s3_bucket.strata_state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.strata.arn
      sse_algorithm     = "aws:kms"
    }
  }
}
