output "state_bucket_name" {
  description = "Paste this value into the S3 backend block in the main project's provider.tf"
  value       = aws_s3_bucket.strata_state.bucket
}
