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

resource "aws_cloudwatch_dashboard" "strata" {
  dashboard_name = "strata-${var.env_tag}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "ALB — Request Count & 5XX Errors"
          period = 300
          stat   = "Sum"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.strata["strataLB"].arn_suffix],
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", aws_lb.strata["strataLB"].arn_suffix],
          ]
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "ALB — Target Response Time (p99)"
          period = 300
          stat   = "p99"
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.strata["strataLB"].arn_suffix],
          ]
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "RDS — CPU & Connections"
          period = 300
          stat   = "Average"
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds.identifier],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.rds.identifier],
          ]
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "ElastiCache Redis — Memory & Connections"
          period = 300
          stat   = "Average"
          metrics = [
            ["AWS/ElastiCache", "DatabaseMemoryUsagePercentage", "ReplicationGroupId", var.elasticache.replication_group_id],
            ["AWS/ElastiCache", "CurrConnections", "ReplicationGroupId", var.elasticache.replication_group_id],
          ]
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "ECS — CPU & Memory Utilization"
          period = 300
          stat   = "Average"
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", "strata-app-cluster"],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", "strata-app-cluster"],
          ]
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "ASG — Healthy Host Count"
          period = 300
          stat   = "Average"
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", aws_lb_target_group.strata["strataInstance"].arn_suffix, "LoadBalancer", aws_lb.strata["strataLB"].arn_suffix],
          ]
        }
      },
    ]
  })
}