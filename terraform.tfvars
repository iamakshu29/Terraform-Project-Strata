aws_region = "ap-south-1"

env_tag = "dev"

vpc = {
  cidr = "10.0.0.0/16"
}

# Subnet Types
public_subnets = {
  "us-east-1a" = {
    cidr = "10.0.1.0/24"
    az   = "us-east-1a"
  }

  "us-east-1b" = {
    cidr = "10.0.2.0/24"
    az   = "us-east-1b"
  }

  "us-east-1c" = {
    cidr = "10.0.3.0/24"
    az   = "us-east-1c"
  }
}

private_subnets = {
  "us-east-1a" = {
    cidr = "10.0.11.0/24"
    az   = "us-east-1a"
  }

  "us-east-1b" = {
    cidr = "10.0.15.0/24"
    az   = "us-east-1b"
  }

  "us-east-1c" = {
    cidr = "10.0.19.0/24"
    az   = "us-east-1c"
  }
}

data_subnets = {
  "us-east-1a" = {
    cidr = "10.0.101.0/24"
    az   = "us-east-1a"
  }

  "us-east-1b" = {
    cidr = "10.0.102.0/24"
    az   = "us-east-1b"
  }

  "us-east-1c" = {
    cidr = "10.0.103.0/24"
    az   = "us-east-1c"
  }
}

nat_gateway_azs = ["us-east-1a", "us-east-1b"]

# NACL Rules for Subnets
public_nacl_rules = {
  ingress = {
    ingress_1 = {
      protocol  = "tcp"
      rule_no   = 100
      action    = "allow"
      from_port = 80
      to_port   = 80
    }
    ingress_2 = {
      protocol  = "tcp"
      rule_no   = 101
      action    = "allow"
      from_port = 443
      to_port   = 443
    }
  }

  egress = {
    egress_1 = {
      protocol   = "tcp"
      rule_no    = 100
      action     = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 1024
      to_port    = 65535
    }
  }
}

private_nacl_rules = {
  ingress = {
    ingress_1 = {
      protocol   = "tcp"
      rule_no    = 100
      action     = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 80
      to_port    = 80
    }

    ingress_2 = {
      protocol   = "tcp"
      rule_no    = 101
      action     = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 443
      to_port    = 443
    }
  }

  egress = {
    egress_1 = {
      protocol   = "tcp"
      rule_no    = 100
      action     = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 1024
      to_port    = 65535
    }
  }
}

data_nacl_rules = {
  ingress = {
    ingress_1 = {
      protocol  = "tcp"
      rule_no   = 100
      action    = "allow"
      from_port = 80
      to_port   = 80
    }

    ingress_2 = {
      protocol  = "tcp"
      rule_no   = 101
      action    = "allow"
      from_port = 443
      to_port   = 443
    }
  }

  egress = {
    egress_1 = {
      protocol   = "tcp"
      rule_no    = 100
      action     = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 1024
      to_port    = 65535
    }
  }
}


route = {
  public_routes = {
    us-east-1a = {
      destination_cidr = "10.0.1.0/24"
    }
    us-east-1b = {
      destination_cidr = "10.0.2.0/24"

    }
    us-east-1c = {
      destination_cidr = "10.0.3.0/24"
    }
  }
  private_routes = {
    us-east-1a = {
      destination_cidr = "10.0.11.0/24"
    }
    us-east-1b = {
      destination_cidr = "10.0.15.0/24"
    }
    us-east-1c = {
      destination_cidr = "10.0.19.0/24"
    }
  }
  data_routes = {
    us-east-1a = {
      destination_cidr = "10.0.101.0/24"
    }
    us-east-1b = {
      destination_cidr = "10.0.102.0/24"
    }
    us-east-1c = {
      destination_cidr = "10.0.103.0/24"
    }
  }
}


# ---------------------------------------------------
security_group = {
  alb = {
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

rds = {
  allocated_storage          = 50
  auto_minor_version_upgrade = false # Custom for SQL Server does not support minor version upgrades
  backup_retention_period    = 7
  identifier                 = "strata-db"
  multi_az                   = true
  publicly_accessible        = false
  deletion_protection        = true
  storage_encrypted          = true
  skip_final_snapshot        = false
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
  subnet_az                   = "us-east-1a"
  subnet_type                 = "public"
  associate_public_ip_address = true
  ebs_size                    = 40
}

launch_template = {
  instance_type               = "t2.xa.large"
  subnet_az                   = "us-east-1b"
  subnet_type                 = "private"
  associate_public_ip_address = false
  volume_size = 50
  volume_type = "gp3"
  encrypted = true
  deletion_on_termination = true
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

iam_policy = {
  "role_ecs_task" = {
    "s3_read_write" = {
      sid    = "S3ReadWrite"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:WriteObject"
      ]
      resources = ["arn:aws:s3:::my-bucket/*"]
    }
    "read_secrets" = {
      sid      = "ReadSecrets"
      effect   = "Allow"
      actions  = ["secretsmanager:GetSecretValue"]
      resources = ["arn:aws:secretsmanager:us-east-1:123456789012:secret:*"]
    }
    "cloudwatch_logs" = {
      sid      = "ReadLog"
      effect   = "Allow"
      actions  = ["ssm:*"]
      resources = ["*"]
    }
    "x-ray_write" = {
      sid      = "WriteXRay"
      effect   = "Allow"
      actions  = ["ssm:*"]
      resources = ["*"]
    }
  }
  role_ec2_instance = {
    "cloudwatch_agent" = {
      sid      = "ReadLogs"
      effect   = "Allow"
      actions  = ["ssm:*"]
      resources = []
    }
    "ssm_managed_instance" = {
      sid      = "ManageSSM"
      effect   = "Allow"
      actions  = ["ssm:*"]
      resources = ["*"]
    }
  }
}