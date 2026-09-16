output "bucket_ids" {
	value = { for key, bucket in aws_s3_bucket.strata_bucket : key => bucket.id }
}

output "bucket_names" {
	value = { for key, bucket in aws_s3_bucket.strata_bucket : key => bucket.bucket }
}
