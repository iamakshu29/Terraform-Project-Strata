output "alb_dns_name" {
  description = "ALB DNS name — use this to test before DNS propagates"
  value       = aws_lb.strata["strataLB"].dns_name
}