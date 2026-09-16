# Database
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.strata_db.endpoint
  sensitive   = true
}