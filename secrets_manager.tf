# defines the secret container
resource "aws_secretsmanager_secret" "strata_db_secret" {
  description = "Production database credentials for Strata server"
  name        = "starta_secrets_manager"
  kms_key_id  = aws_kms_key.strata.arn
  # 0 = immediate deletion on destroy, avoiding the "scheduled for deletion" re-creation block
  recovery_window_in_days = 0

  tags = merge({ Name = "strata-db-secret" }, local.tags)
}

# To stores the actual username/password
resource "aws_secretsmanager_secret_version" "strata_db_secret_val" {
  secret_id     = aws_secretsmanager_secret.strata_db_secret.id
  secret_string = jsonencode(var.secrets)
}

# Command
# aws secretsmanager delete-secret --region ap-south-1 --secret-id starta_secrets_manager s--force-delete-without-recovery
