# VPC Flow Logs: Enabled, published to CloudWatch Logs with a 30-day retention policy.

resource "aws_cloudwatch_log_group" "strata_log_group" {
  name              = "strata-cloudwatch-log-group"
  retention_in_days = var.cloudwatch.retention_in_days
  tags              = local.tags
}

resource "aws_flow_log" "strata_flow_log" {
  iam_role_arn    = aws_iam_role.strata[var.role_names.vpc_flow_log_role_key].arn
  log_destination = aws_cloudwatch_log_group.strata_log_group.arn
  traffic_type    = "ALL"

  vpc_id = aws_vpc.strata.id
}

# https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/aws-services-cloudwatch-metrics.html

resource "aws_cloudwatch_metric_alarm" "strata_metric_alarm_cw" {
  alarm_name                = "strata-cw-alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  threshold                 = 80
  alarm_description         = "This metric monitors ec2 cpu utilization"
  insufficient_data_actions = []

  dynamic "metric_query" {
    for_each = var.metrics
    content {
      id = metric_query.key

      metric {
        metric_name = metric_query.value.metric_name
        namespace   = metric_query.value.namespace
        period      = metric_query.value.period
        stat        = metric_query.value.stat
        unit        = metric_query.value.unit

        dimensions = {
          (metric_query.value.dimension_key) = metric_query.value.dimension_value
        }
      }
    }
  }
}



