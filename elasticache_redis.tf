# ElastiCache Redis — encrypted at rest (KMS) and in transit (TLS),
# deployed into the data subnets across 2 AZs for high availability.

resource "aws_elasticache_subnet_group" "strata_redis" {
  name       = "strata-redis-subnet-group"
  subnet_ids = [for s in aws_subnet.strata_data_subnet : s.id]

  tags = merge({ Name = "strata-redis-subnet-group" }, local.tags)
}

resource "aws_elasticache_replication_group" "strata_redis" {
  replication_group_id = var.elasticache.replication_group_id
  description          = var.elasticache.description

  node_type            = var.elasticache.node_type
  num_cache_clusters   = var.elasticache.num_cache_clusters
  port                 = var.elasticache.port
  parameter_group_name = var.elasticache.parameter_group_name

  subnet_group_name  = aws_elasticache_subnet_group.strata_redis.name
  security_group_ids = [aws_security_group.strata_sg["redis"].id]

  # Encryption — security requirement
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  kms_key_id                 = aws_kms_key.strata.arn

  # Automatic failover requires num_cache_clusters >= 2
  automatic_failover_enabled = var.elasticache.num_cache_clusters >= 2

  # Maintenance and backups
  maintenance_window       = var.elasticache.maintenance_window
  snapshot_retention_limit = var.elasticache.snapshot_retention_limit
  snapshot_window          = var.elasticache.snapshot_window

  apply_immediately = var.elasticache.apply_immediately

  tags = merge({ Name = "strata-redis" }, local.tags)
}
