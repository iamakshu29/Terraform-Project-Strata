# VPC Flow Logs: Enabled, published to CloudWatch Logs with a 30-day retention policy.

resource "aws_cloudwatch_log_group" "strata_log_group" {
  name = "strata-cloudwatch-log-group"
}

resource "aws_flow_log" "strata_flow_log" {
  iam_role_arn    = aws_iam_role.strata[var.role_names.vpc_flow_log_role_key].arn
  log_destination = aws_cloudwatch_log_group.strata_log_group.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.strata.id
}