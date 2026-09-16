# DNS
output "route53_name_servers" {
  description = "Set these as your domain registrar's NS records after the first apply"
  value       = aws_route53_zone.strata.name_servers
}