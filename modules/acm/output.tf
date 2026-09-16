# TLS
output "acm_certificate_arn" {
  description = "ARN of the validated ACM certificate"
  # value       = aws_acm_certificate_validation.strata.certificate_arn
  value = aws_acm_certificate.strata.arn
}