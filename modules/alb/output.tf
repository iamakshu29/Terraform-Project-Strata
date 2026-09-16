output "alb_dns_name" {
  description = "ALB DNS name — use this to test before DNS propagates"
  value       = aws_lb.strata["strataLB"].dns_name
}

output "alb_zone_id" {
  value = aws_lb.strata["strataLB"].zone_id
}

output "alb_arn_suffix" {
  value = aws_lb.strata["strataLB"].arn_suffix
}

output "target_group_arn_suffix" {
  value = aws_lb_target_group.strata["strataInstance"].arn_suffix
}

output "target_group_arns" {
  value = { for key, group in aws_lb_target_group.strata : key => group.arn }
}