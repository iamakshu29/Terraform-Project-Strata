resource "aws_s3_bucket" "strata_bucket" {
  for_each = var.s3

  bucket = each.key

  tags = local.tags
}

# S3 Versioning block
resource "aws_s3_bucket_versioning" "strata_s3_versioning" {
  for_each = var.s3

  bucket = aws_s3_bucket.strata_bucket[each.key].id
  versioning_configuration {
    status = each.value.versioning_status
  }
}

# S3 Public Access block
resource "aws_s3_bucket_public_access_block" "strata_bucket_access_block" {
  for_each = var.s3

  bucket = aws_s3_bucket.strata_bucket[each.key].id

  block_public_acls       = each.value.block_public_acls
  block_public_policy     = each.value.block_public_policy
  ignore_public_acls      = each.value.ignore_public_acls
  restrict_public_buckets = each.value.restrict_public_buckets
}

# S3 Lifecycle Configuration block
resource "aws_s3_bucket_lifecycle_configuration" "starta_s3_lifecycle_config" {
  for_each = var.s3

  bucket = aws_s3_bucket.strata_bucket[each.key].id

  rule {
    id     = each.value.rule_id
    status = each.value.status

    filter {}

    transition {
      days          = each.value.first_transition_storage_days
      storage_class = each.value.first_transition_storage_type
    }

    transition {
      days          = each.value.second_transiton_storage_days
      storage_class = each.value.second_transition_storage_type
    }

    expiration {
      days = each.value.delete_data_after
    }
  }
}

# S3 SSE-encryption with KMS block
resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  for_each = var.s3
  bucket   = aws_s3_bucket.strata_bucket[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.strata.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Bucket policy granting ECS task and EC2 roles access to application S3 buckets.
# Skips the logging bucket (logging = true) which has its own dedicated policy.
data "aws_iam_policy_document" "strata_bucket_policy" {
  for_each = { for k, v in var.s3 : k => v if !v.logging }

  statement {
    sid    = "ECSAndEC2BucketAccess"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.strata[var.role_names.ecs_task_role_key].arn,
        aws_iam_role.strata[var.role_names.ec2_role_key].arn,
      ]
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.strata_bucket[each.key].arn,
      "${aws_s3_bucket.strata_bucket[each.key].arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "strata_bucket_policy" {
  for_each = { for k, v in var.s3 : k => v if !v.logging }

  bucket = aws_s3_bucket.strata_bucket[each.key].id
  policy = data.aws_iam_policy_document.strata_bucket_policy[each.key].json
}