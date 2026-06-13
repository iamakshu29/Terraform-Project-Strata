resource "aws_kms_key" "strata" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = var.kms_key.deletion_window_in_days
  enable_key_rotation     = var.kms_key.enable_key_rotation
}
