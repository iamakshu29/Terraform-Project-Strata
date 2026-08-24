# DNS
output "route53_name_servers" {
  description = "Set these as your domain registrar's NS records after the first apply"
  value       = aws_route53_zone.strata.name_servers
}

# TLS
output "acm_certificate_arn" {
  description = "ARN of the validated ACM certificate"
  # value       = aws_acm_certificate_validation.strata.certificate_arn
  value = aws_acm_certificate.strata.arn
}

# Cache
output "redis_primary_endpoint" {
  description = "Redis primary endpoint for write operations"
  value       = aws_elasticache_replication_group.strata_redis.primary_endpoint_address
}

output "redis_reader_endpoint" {
  description = "Redis reader endpoint for read-heavy workloads"
  value       = aws_elasticache_replication_group.strata_redis.reader_endpoint_address
}

# Networking
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.strata.id
}

output "alb_dns_name" {
  description = "ALB DNS name — use this to test before DNS propagates"
  value       = aws_lb.strata["strataLB"].dns_name
}

# Database
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.strata_db.endpoint
  sensitive   = true
}
