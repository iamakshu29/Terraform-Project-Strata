
resource "aws_acm_certificate" "strata" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge({ Name = "strata-certificate" }, local.tags)
}

  # Validation uses the Route 53 records created in route53.tf
  # Uncomment and apply again when u have proper dns with nameservers.
# resource "aws_acm_certificate_validation" "strata" {
#   certificate_arn         = aws_acm_certificate.strata.arn
#   validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
# }

