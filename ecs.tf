# depends_on = [aws_iam_role_policy.foo] — wrong reference, doesn't exist
# aws_cloudwatch_log_group.example.name — should be strata_log_group
# data.aws_region.current.region — attribute should be .name, and data "aws_region" "current" not declared in data.tf
# execution_role_arn = "" and task_role_arn = "" — empty strings, need actual IAM role references
# network_configuration subnets and security_groups are empty []

# EFS
resource "aws_efs_file_system" "strata_efs" {
  for_each       = var.efs
  creation_token = each.value.creation_token
  encrypted      = each.value.encrypted
  kms_key_id     = aws_kms_key.strata.id

  lifecycle_policy {
    transition_to_ia = each.value.transition_to_ia
  }

  tags = local.tags
}

# Logical cluster where the service runs.
resource "aws_ecs_cluster" "strata_cluster" {
  for_each = var.ecs_cluster

  name = each.value.name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_service_discovery_http_namespace" "strata_ecs_namespace" {
  for_each = var.service_discovery

  name        = each.value.name
  description = each.value.description
}

resource "aws_ecs_task_definition" "service" {
  for_each = var.task_definitions

  family                   = each.value.family
  requires_compatibilities = each.value.requires_compatibilities
  network_mode             = each.value.network_mode
  execution_role_arn       = ""
  task_role_arn            = ""
  cpu                      = each.value.cpu
  memory                   = each.value.memory

  container_definitions = jsonencode([
    for c in each.value.tasks : {

      name      = c.name
      image     = c.image
      cpu       = c.cpu
      memory    = c.memory
      essential = c.essential
      portMappings = [
        {
          containerPort = c.containerPort
          hostPort      = c.hostPort
        }
      ]
    }
  ])

  dynamic "volume" {
    for_each = each.value.volumes

    content {
      name = volume.value.name

      efs_volume_configuration {
        file_system_id = aws_efs_file_system.strata_efs[volume.value.name].id
      }
    }
  }
}

# References the cluster and task definition.
resource "aws_ecs_service" "strata_service" {
  for_each        = var.ecs_service

  name            = each.value.name
  cluster         = aws_ecs_cluster.strata_cluster[each.value.cluster_key].id
  task_definition = aws_ecs_task_definition.service[each.value.task_key].arn
  desired_count   = each.value.desired_count
  depends_on      = [aws_iam_role_policy.foo]
  launch_type     = each.value.launch_type

  service_connect_configuration {
    enabled   = each.value.enabled
    namespace = aws_service_discovery_http_namespace.strata_ecs_namespace[each.value.namespace_key].arn

    log_configuration {
      log_driver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.example.name
        "awslogs-region"        = data.aws_region.current.region
        "awslogs-stream-prefix" = "service-connect"
      }
    }

    service {
      port_name      = each.value.service_port_name
      discovery_name = each.value.service_discovery_name

      client_alias {
        dns_name = each.value.dns_name
        port     = each.value.port
      }
    }
  }

  network_configuration {
    subnets          = []
    security_groups  = []
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.strata_ecs.arn
    container_name   = each.value.lb_container_name
    container_port   = each.value.container_port
  }

  alarms {
    enable   = each.value.alarms_enabled
    rollback = each.value.rollback
    alarm_names = [
      aws_cloudwatch_metric_alarm.strata_metric_alarm_cw.alarm_name
    ]
  }
}