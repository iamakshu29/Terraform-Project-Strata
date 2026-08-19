# Public hosted zone — delegates DNS authority for var.domain_name to Route 53.
# After first apply, copy the name_servers output to your domain registrar's NS records.
resource "aws_route53_zone" "strata" {
  name = var.domain_name
  tags = local.tags
}

# ACM DNS validation records — Route 53 creates and serves these automatically
resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.strata.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.strata.zone_id
}

# ALB alias A record — routes domain traffic to the ALB (no TTL needed for aliases)
resource "aws_route53_record" "alb" {
  zone_id = aws_route53_zone.strata.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.strata["strataLB"].dns_name
    zone_id                = aws_lb.strata["strataLB"].zone_id
    evaluate_target_health = true
  }
}

output "route53_name_servers" {
  description = "Set these as your domain registrar's NS records after the first apply"
  value       = aws_route53_zone.strata.name_servers
}
