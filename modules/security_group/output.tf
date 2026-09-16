output "security_group_ids" {
	description = "Security group IDs keyed by security group name"
	value       = { for key, security_group in aws_security_group.strata_sg : key => security_group.id }
}
