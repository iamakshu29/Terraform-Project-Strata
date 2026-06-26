aws_region = "ap-south-1"

env_tag = "dev"

vpc = {
  cidr = "10.0.0.0/16"
}

# Subnet Types
public_subnets = {
  "ap-south-1a" = {
    cidr = "10.0.1.0/24"
    az   = "ap-south-1a"
  }

  "ap-south-1b" = {
    cidr = "10.0.2.0/24"
    az   = "ap-south-1b"
  }

  "ap-south-1c" = {
    cidr = "10.0.3.0/24"
    az   = "ap-south-1c"
  }
}

private_subnets = {
  "ap-south-1a" = {
    cidr = "10.0.11.0/24"
    az   = "ap-south-1a"
  }

  "ap-south-1b" = {
    cidr = "10.0.15.0/24"
    az   = "ap-south-1b"
  }

  "ap-south-1c" = {
    cidr = "10.0.19.0/24"
    az   = "ap-south-1c"
  }
}

data_subnets = {
  "ap-south-1a" = {
    cidr = "10.0.101.0/24"
    az   = "ap-south-1a"
  }

  "ap-south-1b" = {
    cidr = "10.0.102.0/24"
    az   = "ap-south-1b"
  }

  "ap-south-1c" = {
    cidr = "10.0.103.0/24"
    az   = "ap-south-1c"
  }
}

nat_gateway_azs = ["ap-south-1a", "ap-south-1b"]

# NACL Rules for Subnets
public_nacl_rules = {
  ingress = {
    ingress_1 = {
      protocol   = "tcp"
      rule_no    = 100
      action     = "allow"
      from_port  = 80
      to_port    = 80
      cidr_block = "0.0.0.0/0"
    }
    ingress_2 = {
      protocol   = "tcp"
      rule_no    = 101
      action     = "allow"
      from_port  = 443
      to_port    = 443
      cidr_block = "0.0.0.0/0"
    }
  }

  egress = {
    egress_1 = {
      protocol   = "tcp"
      rule_no    = 100
      action     = "allow"
      from_port  = 1024
      to_port    = 65535
      cidr_block = "0.0.0.0/0"
    }
  }
}

private_nacl_rules = {
  ingress = {
    ingress_1 = {
      protocol   = "tcp"
      rule_no    = 100
      action     = "allow"
      from_port  = 80
      to_port    = 80
      cidr_block = "0.0.0.0/0"
    }

    ingress_2 = {
      protocol   = "tcp"
      rule_no    = 101
      action     = "allow"
      from_port  = 443
      to_port    = 443
      cidr_block = "0.0.0.0/0"
    }
  }

  egress = {
    egress_1 = {
      protocol   = "tcp"
      rule_no    = 100
      action     = "allow"
      from_port  = 1024
      to_port    = 65535
      cidr_block = "0.0.0.0/0"
    }
  }
}

data_nacl_rules = {
  ingress = {
    ingress_1 = {
      protocol   = "tcp"
      rule_no    = 100
      action     = "allow"
      from_port  = 80
      to_port    = 80
      cidr_block = "0.0.0.0/0"
    }

    ingress_2 = {
      protocol   = "tcp"
      rule_no    = 101
      action     = "allow"
      from_port  = 443
      to_port    = 443
      cidr_block = "0.0.0.0/0"
    }
  }

  egress = {
    egress_1 = {
      protocol   = "tcp"
      rule_no    = 100
      action     = "allow"
      from_port  = 1024
      to_port    = 65535
      cidr_block = "0.0.0.0/0"
    }
  }
}

route = {
  public_routes = {
    ap-south-1a = {
      destination_cidr = "10.0.1.0/24"
    }
    ap-south-1b = {
      destination_cidr = "10.0.2.0/24"

    }
    ap-south-1c = {
      destination_cidr = "10.0.3.0/24"
    }
  }
  private_routes = {
    ap-south-1a = {
      destination_cidr = "10.0.11.0/24"
    }
    ap-south-1b = {
      destination_cidr = "10.0.15.0/24"
    }
    ap-south-1c = {
      destination_cidr = "10.0.19.0/24"
    }
  }
  data_routes = {
    ap-south-1a = {
      destination_cidr = "10.0.101.0/24"
    }
    ap-south-1b = {
      destination_cidr = "10.0.102.0/24"
    }
    ap-south-1c = {
      destination_cidr = "10.0.103.0/24"
    }
  }
}

# ---------------------------------------------------
security_group = {
  strataLB = {
    ingress = {
      https = {
        cidr_ipv4   = "0.0.0.0/0"
        from_port   = 443
        to_port     = 443
        ip_protocol = "tcp"
      }
    }
  }

  ecs = {
    ingress = {
      alb = {
        source_security_group = "alb"
        from_port             = 8080
        to_port               = 8080
        ip_protocol           = "tcp"
      }
    }
  }

  ec2 = {
    ingress = {
      alb = {
        source_security_group = "alb"
        from_port             = 8080
        to_port               = 8080
        ip_protocol           = "tcp"
      }
    }
  }

  bastion = {
    ingress = {
      ssh = {
        # Replace with your office/home IP
        cidr_ipv4   = "0.0.0.0/0" # Use VPN or home IP instead
        from_port   = 22
        to_port     = 22
        ip_protocol = "tcp"
      }
    }
  }

  rds = {
    ingress = {
      ecs = {
        source_security_group = "ecs"
        from_port             = 5432
        to_port               = 5432
        ip_protocol           = "tcp"
      }

      ec2 = {
        source_security_group = "ec2"
        from_port             = 5432
        to_port               = 5432
        ip_protocol           = "tcp"
      }
    }
  }

  redis = {
    ingress = {
      ecs = {
        source_security_group = "ecs"
        from_port             = 6379
        to_port               = 6379
        ip_protocol           = "tcp"
      }

      ec2 = {
        source_security_group = "ec2"
        from_port             = 6379
        to_port               = 6379
        ip_protocol           = "tcp"
      }
    }
  }
}

# ---------------------------------------------------------
lb = {
  strataLB = {
    internal           = true
    load_balancer_type = "application"
    enable_deletion_protection = true
    port = "443"
    protocol = "HTTPS"
  }
}

target_group = {
  strataInstance = {
    port        = 8443
    protocol    = "HTTPS"
    target_type = "instance"
    type        = "forward"
    lb_key      = "strataLB" # Matches the key in var.lb
  }
  strataECS = {
    port        = 8442
    protocol    = "HTTPS"
    target_type = "ip"
    type        = "forward"
    lb_key      = "strataLB" # Matches the key in var.lb
  }
}

# ---------------------------------------------------------

rds = {
  allocated_storage          = 50
  auto_minor_version_upgrade = false # Custom for SQL Server does not support minor version upgrades
  backup_retention_period    = 7
  identifier                 = "strata-db"
  multi_az                   = true
  publicly_accessible        = false
  deletion_protection        = true
  storage_encrypted          = true
  skip_final_snapshot        = false # true for Prod only
  apply_immediately          = false
  engine_version             = "16.2"
  instance_class             = "db.t3.medium" # "db.t3.medium" for dev, "db.r6g.large" minimum for prod
  engine                     = "postgres"
  db_name                    = "testDB"
}

kms_key = {
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

# ---------------------------------------------------------
secrets = {
  "username" = "strata_admin"
  "password" = "SuperSecurePassword123!"
}

# ---------------------------------------------------------
aws_bastian_instance = {
  instance_type               = "t2.medium"
  subnet_az                   = "ap-south-1a"
  subnet_type                 = "public"
  associate_public_ip_address = true
  ebs_size                    = 40
}

launch_template = {
  instance_type               = "t2.xa.large"
  subnet_az                   = "ap-south-1b"
  subnet_type                 = "private"
  associate_public_ip_address = false
  volume_size                 = 50
  volume_type                 = "gp3"
  encrypted                   = true
  deletion_on_termination     = true
}

asg = {
  max_size                  = 3
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  delete                    = "15m"
}

# extra_tags = {

# }

# What can the role do
iam_policy = {
  "role_ecs_task_execution" = {
    "s3_read_write" = {
      sid    = "S3ReadWrite"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:WriteObject"
      ]
      resources = ["*"]
    }
    "read_secrets" = {
      sid       = "ReadSecrets"
      effect    = "Allow"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = ["*"]
    }
    "read_cloudwatch_logs" = {
      sid       = "ReadLog"
      effect    = "Allow"
      actions   = ["ssm:*"]
      resources = ["*"]
    }
    "x-ray_write" = {
      sid       = "WriteXRay"
      effect    = "Allow"
      actions   = ["ssm:*"]
      resources = ["*"]
    }
    "rds_access-rw" = {
      sid       = "RDSReadWrite"
      effect    = "Allow"
      actions   = ["rds-db:connect"]
      resources = ["*"]
    }
    "ecr-access-rw" = {
      sid       = "ECRReadWrite"
      effect    = "Allow"
      actions   = ["ecr:*"]
      resources = ["*"]
    }
  }
  role_ec2_instance = {
    "read_cloudwatch_logs" = {
      sid       = "ReadLogs"
      effect    = "Allow"
      actions   = ["ssm:*"]
      resources = ["*"]
    }
    "ssm_managed_instance" = {
      sid       = "ManageSSM"
      effect    = "Allow"
      actions   = ["ssm:*"]
      resources = ["*"]
    }
    "s3_read_write" = {
      sid    = "S3ReadWrite"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:PutObject"
      ]
      resources = ["*"]
    }
    "read_secrets" = {
      sid       = "ReadSecrets"
      effect    = "Allow"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = ["*"]
    }
    "rds_access-rw" = {
      sid       = "RDSReadWrite"
      effect    = "Allow"
      actions   = ["rds-db:connect"]
      resources = ["*"]
    }
  }
  role_ecs_task = {
    "s3_read_write" = {
      sid    = "S3ReadWrite"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:PutObject"
      ]
      resources = ["*"]
    }
    "read_secrets" = {
      sid       = "ReadSecrets"
      effect    = "Allow"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = ["*"]
    }
    "rds_access_rw" = {
      sid       = "RDSReadWrite"
      effect    = "Allow"
      actions   = ["rds-db:connect"]
      resources = ["*"]
    }
    "write_cloudwatch_logs" = {
      sid    = "WriteLogs"
      effect = "Allow"
      actions = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      resources = ["*"]
    }
    "xray_write" = {
      sid    = "WriteXRay"
      effect = "Allow"
      actions = [
        "xray:PutTraceSegments",
        "xray:PutTelemetryRecords"
      ]
      resources = ["*"]
    }
  }
  role_vpc_flow_log = {
    "manage_vpc_glow_log" = {
      sid    = "VPCLogAcess"
      effect = "Allow"
      actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      resources = ["*"]
    }
  }

}

# who can use the role 
assume_role_policy = {
  role_ec2_instance = {
    Version           = "2012-10-17"
    Action            = "sts:AssumeRole"
    Effect            = "Allow"
    Sid               = ""
    Principal_Service = "ec2.amazonaws.com"
  }
  role_ecs_task_execution = {
    Version           = "2012-10-17"
    Action            = "sts:AssumeRole"
    Effect            = "Allow"
    Sid               = ""
    Principal_Service = "ecs-tasks.amazonaws.com"
  }
  role_ecs_task = {
    Version           = "2012-10-17"
    Action            = "sts:AssumeRole"
    Effect            = "Allow"
    Sid               = ""
    Principal_Service = "ecs-tasks.amazonaws.com"
  }
  role_vpc_flow_log = {
    Version           = "2012-10-17"
    Action            = "sts:AssumeRole"
    Effect            = "Allow"
    Sid               = ""
    Principal_Service = "vpc-flow-logs.amazonaws.com"
  }
}

role_names = {
  ec2_role_key          = "role_ec2_instance"
  ecs_role_key          = "role_ecs_task_execution"
  ecs_task_role_key     = "role_ecs_task"
  vpc_flow_log_role_key = "role_vpc_flow_log"
}

cloudwatch = {
  retention_in_days = 30
}

s3 = {
  strata_bucket = {
    block_public_acls              = true
    block_public_policy            = true
    ignore_public_acls             = true
    restrict_public_buckets        = true
    rule_id                        = "strata-s3-rule"
    versioning_status              = "Enabled"
    status                         = "Enabled"
    first_transition_storage_type  = "STANDARD_IA"
    first_transition_storage_days  = 30
    second_transition_storage_type = "GLACIER"
    second_transiton_storage_days  = 90
    delete_data_after              = 365
    logging = false
  }
  strata_logging_bucket = {
    block_public_acls              = true
    block_public_policy            = true
    ignore_public_acls             = true
    restrict_public_buckets        = true
    rule_id                        = "strata-s3-logging-rule"
    status                         = "Enabled"
    versioning_status              = "Enabled"
    first_transition_storage_type  = "STANDARD_IA"
    first_transition_storage_days  = 30
    second_transition_storage_type = "GLACIER"
    second_transiton_storage_days  = 90
    delete_data_after              = 365
    logging                        = true
  }
}


# ssm_paramter_store = {

# }


# change dim_key and value
metrics = {
  metric_1 = {
    metric_name = "HTTPCode_ELB_5XX_Rate"
    namespace   = "AWS/ApplicationELB"
    period      = 120
    stat        = "Average"
    # for percentage --extended-statistics p99 p95 p50.
    unit            = "Count"
    dimension_key   = "LoadBalancer"
    dimension_value = "app/web"
  }
  metric_2 = {
    metric_name     = "RDS_Connections_Count"
    namespace       = "AWS/RDS"
    period          = 120
    stat            = "Sum"
    unit            = "Count"
    dimension_key   = "LoadBalancer"
    dimension_value = "app/web"
  }
  metric_3 = {
    metric_name     = "ECS_CPU_Utilization"
    namespace       = "AWS/ECS"
    period          = 120
    stat            = "Sum"
    unit            = "Count"
    dimension_key   = "LoadBalancer"
    dimension_value = "app/web"
  }
  metric_4 = {
    metric_name     = "ElastiCache_Redis_Memory_Utilization"
    namespace       = "AWS/RedisCache"
    period          = 120
    stat            = "Average"
    unit            = "Count"
    dimension_key   = "LoadBalancer"
    dimension_value = "app/web"
  }
}

cloudtrail = {
  name                          = "strata-trail"
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = true
}

efs = {
  strata_efs = {
    creation_token   = "strata-efs"
    encrypted        = true
    transition_to_ia = "AFTER_30_DAYS"
  }
}

ecs_cluster = {
  strata_cluster = {
    name = "strata-app-cluster"
  }
}

ecs_service = {
  strata_service = {
    task_key                     = "strata_task"              # must match task_definitions key
    cluster_key                  = "strata_cluster"           # must match ecs_cluster key
    namespace_key                = "strata_service_discovery" # must match service_discovery key
    name                         = "mongodb"
    desired_count                = 3
    launch_type                  = "FARGATE"
    enabled                      = true
    logdriver                    = "awslogs"
    log_format                   = "TEXT"
    log_include_query_parameters = "ENABLED"
    service_port_name            = "http"
    service_discovery_name       = "example"
    dns_name                     = "example"
    port                         = 8080
    placement_strategy_type      = "binpack"
    placement_strategy_field     = "cpu"
    ecs_target_group             = "strataECS" # same as target_group key for ecs
    lb_container_name            = "eaxmple-container"
    container_port               = 8080
    alarms_enabled               = true
    rollback                     = true
    subnet_keys                  = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
    sg_keys                      = ["ecs"]
  }
}

service_discovery = {
  strata_service_discovery = {
    name        = "development"
    description = "Strata Description of my app"
  }
}

task_definitions = {
  strata_task = {
    family                   = "service"
    requires_compatibilities = ["FARGATE"]
    network_mode             = "awsvpc"
    cpu                      = 256
    memory                   = 512
    tasks = {
      image_1 = {
        name          = "strata-app-1"
        image         = "strata-image-1"
        cpu           = 10
        memory        = 512
        essential     = true
        containerPort = 80
        hostPort      = 80
        network_mode  = "awsvpc"
      }
      image_2 = {
        name          = "strata-app-2"
        image         = "strata-image-2"
        cpu           = 10
        memory        = 256
        essential     = true
        containerPort = 443
        hostPort      = 443
        network_mode  = "awsvpc"
      }
    }
    volumes = {
      strata_efs = {
        name = "strata-efs"
      }
    }
  }
}