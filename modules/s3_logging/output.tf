output "logging_bucket_name" {
	description = "Name of the S3 bucket used for centralized logging"
	value       = var.bucket_names["strata-logging-bucket"]
}
