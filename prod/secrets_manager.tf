# defines the secret container
resource "aws_secretsmanager_secret" "strata_db_secret" {
  description = "Production database credentials for Strata server"
  name        = "starta_secrets_manager"
  kms_key_id  = aws_kms_key.strata.id

  tags = local.tags
}

# To stores the actual username/password
resource "aws_secretsmanager_secret_version" "strata_db_secret_val" {
  secret_id     = aws_secretsmanager_secret.strata_db_secret.id
  secret_string = jsonencode(var.secrets)
}