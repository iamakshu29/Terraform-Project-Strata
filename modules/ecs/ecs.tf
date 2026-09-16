# EFS
resource "aws_efs_file_system" "strata_efs" {
  for_each       = var.efs
  creation_token = each.value.creation_token
  encrypted      = each.value.encrypted
  kms_key_id     = var.kms_key_arn

  lifecycle_policy {
    transition_to_ia = each.value.transition_to_ia
  }

  tags = merge({ Name = "strata-efs-${each.key}-${var.env_tag}" }, local.tags)
}

# Mount targets — one per private subnet AZ so ECS tasks in every AZ can reach EFS
resource "aws_efs_mount_target" "strata" {
  for_each = var.private_subnets

  file_system_id  = aws_efs_file_system.strata_efs["strata_efs"].id
  subnet_id       = var.private_subnet_ids[each.key]
  security_groups = [var.security_group_ids["efs"]]
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
  execution_role_arn       = var.role_arns[var.role_names.ecs_role_key]
  task_role_arn            = var.role_arns[var.role_names.ecs_task_role_key]
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
          name          = c.port_name
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-region"        = data.aws_region.current.region
          
          "awslogs-group"         = "/ecs/${c.name}"
          "awslogs-stream-prefix" = "ecs"
        }
      }

    }
  ])

  dynamic "volume" {
    for_each = each.value.volumes

    content {
      name = volume.value.name

      efs_volume_configuration {
        file_system_id = aws_efs_file_system.strata_efs[volume.key].id
      }
    }
  }
}

# References the cluster and task definition.
resource "aws_ecs_service" "strata_service" {
  for_each = var.ecs_service

  name            = each.value.name
  cluster         = aws_ecs_cluster.strata_cluster[each.value.cluster_key].id
  task_definition = aws_ecs_task_definition.service[each.value.task_key].arn
  desired_count   = each.value.desired_count
  launch_type     = each.value.launch_type

  service_connect_configuration {
    enabled   = each.value.enabled
    namespace = aws_service_discovery_http_namespace.strata_ecs_namespace[each.value.namespace_key].arn

    log_configuration {
      log_driver = "awslogs"
      options = {
        "awslogs-region"        = data.aws_region.current.region
        "awslogs-group"         = var.service_log_group_name
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
    subnets          = [for k in each.value.subnet_keys : var.private_subnet_ids[k]]
    security_groups  = [for k in each.value.sg_keys : var.security_group_ids[k]]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arns[each.value.ecs_target_group]
    container_name   = each.value.lb_container_name
    container_port   = each.value.container_port
  }

  alarms {
    enable   = each.value.alarms_enabled
    rollback = each.value.rollback
    # alarm is for_each = var.metrics so iterate over the map
    alarm_names = var.alarm_names
  }
}
