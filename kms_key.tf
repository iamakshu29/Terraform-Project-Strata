data "aws_iam_policy_document" "kms_key_policy" {
  # Account root — full admin access so the key is never unmanageable
  statement {
    sid       = "Enable IAM root access"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  # EC2 service needs CreateGrant to attach encrypted EBS volumes
  statement {
    sid = "Allow EC2 to use key for EBS"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:DescribeKey",
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ec2.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
}

resource "aws_kms_key" "strata" {
  description             = "CMK for RDS, EBS, S3, ElastiCache, and Secrets Manager"
  deletion_window_in_days = var.kms_key.deletion_window_in_days
  enable_key_rotation     = var.kms_key.enable_key_rotation
  policy                  = data.aws_iam_policy_document.kms_key_policy.json
}

resource "aws_kms_alias" "strata" {
  name          = "alias/strata-rds-key"
  target_key_id = aws_kms_key.strata.key_id
}