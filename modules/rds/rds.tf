resource "aws_db_instance" "strata_db" {
  allocated_storage          = var.rds.allocated_storage
  auto_minor_version_upgrade = var.rds.auto_minor_version_upgrade
  backup_retention_period    = var.rds.backup_retention_period
  identifier                 = var.rds.identifier
  multi_az                   = var.rds.multi_az
  publicly_accessible        = var.rds.publicly_accessible
  deletion_protection        = var.rds.deletion_protection
  storage_encrypted          = var.rds.storage_encrypted
  skip_final_snapshot        = var.rds.skip_final_snapshot
  apply_immediately          = var.rds.apply_immediately
  instance_class             = var.rds.instance_class
  engine_version             = var.rds.engine_version
  engine                     = var.rds.engine
  db_name                    = var.rds.db_name


  # will do with secrets manager
  username               = var.db_credentials["username"]
  password               = var.db_credentials["password"]
  vpc_security_group_ids = [var.security_group_id]
  db_subnet_group_name   = var.db_subnet_group_name
  kms_key_id             = var.kms_key_arn


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
