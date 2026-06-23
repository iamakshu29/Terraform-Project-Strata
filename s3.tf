resource "aws_s3_bucket" "strata_bucket" {
  bucket = "strata-app-bucket"

  tags = local.tags
}

# S3 Versioning block
resource "aws_s3_bucket_versioning" "strata_s3_versioning" {
  bucket = aws_s3_bucket.strata_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Public Access block
resource "aws_s3_bucket_public_access_block" "strata_bucket_access_block" {
  bucket = aws_s3_bucket.strata_bucket.id

  block_public_acls       = try(var.s3.block_public_acls, true)
  block_public_policy     = try(var.s3.block_public_policy, true)
  ignore_public_acls      = try(var.s3.ignore_public_acls, true)
  restrict_public_buckets = try(var.s3.restrict_public_buckets, true)
}

# S3 Lifecycle Configuration block
resource "aws_s3_bucket_lifecycle_configuration" "starta_s3_lifecycle_config" {
  bucket = aws_s3_bucket.strata_bucket.id

  rule {
    id     = "strata-s3-rule"
    status = "Enabled"

    filter {}

    transition {
      days          = var.s3.IA_transition_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.s3.glacier_transiton_days
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

# S3 SSE-encryption with KMS block
resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.strata_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.strata.arn
      sse_algorithm     = "aws:kms"
    }
  }
}