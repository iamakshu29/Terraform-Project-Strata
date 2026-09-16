output "role_arns" {
	description = "IAM role ARNs keyed by role name"
	value       = { for key, role in aws_iam_role.strata : key => role.arn }
}

output "role_names" {
	value = { for key, role in aws_iam_role.strata : key => role.name }
}
