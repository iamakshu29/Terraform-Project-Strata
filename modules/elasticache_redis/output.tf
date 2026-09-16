# Cache
output "redis_primary_endpoint" {
  description = "Redis primary endpoint for write operations"
  value       = aws_elasticache_replication_group.strata_redis.primary_endpoint_address
}

output "redis_reader_endpoint" {
  description = "Redis reader endpoint for read-heavy workloads"
  value       = aws_elasticache_replication_group.strata_redis.reader_endpoint_address
}