# Logical cluster where the service runs.
resource "aws_ecs_cluster" "strata_cluster" {
  name = "strata-app-cluster"
  # VPC is left
  # subnet also

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_service_discovery_http_namespace" "strata_ecs_namespace" {
  name        = "development"
  description = "example"
}

resource "aws_ecs_task_definition" "service" {
  for_each = var.task_definitions

  family                   = "service"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  execution_role_arn = ""
  task_role_arn = ""
  
  container_definitions = jsonencode([
    {
      name      = each.value.name
      image     = each.value.image
      cpu       = each.value.cpu
      memory    = each.value.memory
      essential = each.value.essential
      portMappings = [
        {
          containerPort = each.value.containerPort
          hostPort      = each.value.hostPort
        }
      ]
    }
  ])

  volume {
    name = "service-storage"

    efs_volume_configuration {
      file_system_id = aws_efs_file_system.main.id
    }
  }
}

# References the cluster and task definition.
resource "aws_ecs_service" "mongo" {
  for_each = var.ecs
  name            = each.value.name
  cluster         = aws_ecs_cluster.strata_cluster.id
  task_definition = aws_ecs_task_definition.service[each.key].arn
  desired_count   = each.value.desired_count
  depends_on      = [aws_iam_role_policy.foo]
  launch_type = "FARGATE"

  service_connect_configuration {
    enabled   = each.value.enabled
    namespace = aws_service_discovery_http_namespace.strata_ecs_namespace.arn

    log_configuration {
      log_driver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.example.name
        "awslogs-region"        = data.aws_region.current.region
        "awslogs-stream-prefix" = "service-connect"
      }
    }

    access_log_configuration {
      format                   = each.value.log_format
      include_query_parameters = each.value.log_include_query_parameters
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

  load_balancer {
    target_group_arn = aws_lb_target_group.strata.arn
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