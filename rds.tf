resource "aws_db_instance" "strata" {
  allocated_storage          = try(var.rds.allocated_storage, 50)
  auto_minor_version_upgrade = try(var.rds.auto_minor_version_upgrade, false)
  backup_retention_period    = try(var.rds.backup_retention_period, 7)
  identifier                 = var.rds.identifier
  multi_az                   = try(var.rds.multi_az, true)
  publicly_accessible        = try(var.rds.publicly_accessible, false)
  deletion_protection        = try(var.rds.deletion_protection, true)
  storage_encrypted          = try(var.rds.storage_encrypted, true)
  skip_final_snapshot        = try(var.rds.skip_final_snapshot, false) # true for Prod only
  apply_immediately          = try(var.rds.apply_immediately, false)
  instance_class             = var.rds.instance_class
  engine_version             = var.rds.engine_version
  engine                     = var.rds.engine
  db_name                    = var.rds.db_name


  # will do with secrets manager
  username               = jsondecode(aws_secretsmanager_secret_version.strata_db_secret_val.secret_string)["username"]
  password               = jsondecode(aws_secretsmanager_secret_version.strata_db_secret_val.secret_string)["password"]
  vpc_security_group_ids = [aws_security_group.strata_sg["rds"].id]
  db_subnet_group_name   = aws_db_subnet_group.strata_db_group.name
  kms_key_id             = aws_kms_key.strata.arn


  # Adding a timeouts block allows you to override Terraform's default operational limits
  timeouts {
    create = "3h"
    delete = "3h"
    update = "3h"
  }

  tags = merge({ Name = var.rds.identifier }, local.tags)

  lifecycle {
    ignore_changes = [
      password, # Prevents password from turning up in plans
    ]
  }
}
