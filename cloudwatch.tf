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
  for_each = var.metrics

  alarm_name          = "strata-${each.key}-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  evaluation_periods = 2
  period             = each.value.period
  threshold          = each.value.threshold

  namespace   = each.value.namespace
  metric_name = each.value.metric_name
  statistic   = each.value.stat
  unit        = each.value.unit

  alarm_description = each.value.description

  dimensions = {
    (each.value.dimension_key) = local.dimension_value_to_arn[
      each.value.dimension_value
    ]
  }

  insufficient_data_actions = []
}

# Metrics list comes as [namespace, metric_name, dimension_key, dimension_value]

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
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", local.dimension_value_to_arn["lb-arn_suffix"]],
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", local.dimension_value_to_arn["lb-arn_suffix"]],
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
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", local.dimension_value_to_arn["lb-arn_suffix"]],
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
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", local.dimension_value_to_arn["rds_identifier"]],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", local.dimension_value_to_arn["rds_identifier"]]
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
            ["AWS/ElastiCache", "DatabaseMemoryUsagePercentage", "ReplicationGroupId", local.dimension_value_to_arn["elasticache_rep_group_id"]],
            ["AWS/ElastiCache", "CurrConnections", "ReplicationGroupId", local.dimension_value_to_arn["elasticache_rep_group_id"]]
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
            ["AWS/ECS", "CPUUtilization", "ClusterName", local.dimension_value_to_arn["ecs_cluster"], "ServiceName", local.dimension_value_to_arn["ecs_service"]],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", local.dimension_value_to_arn["ecs_cluster"], "ServiceName", local.dimension_value_to_arn["ecs_service"]]
          ]
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "ALB Target Group — Healthy Host Count"
          period = 300
          stat   = "Average"
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", local.dimension_value_to_arn["lb-target_group"], "LoadBalancer", local.dimension_value_to_arn["lb-arn_suffix"]]
          ]
        }
      },
    ]
  })
}
