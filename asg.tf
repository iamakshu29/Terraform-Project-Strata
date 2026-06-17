# Instance profile — required for EC2 to use the role
resource "aws_iam_instance_profile" "strata" {
  name     = "my-ec2-instance-profile"
  role     = aws_iam_role.strata[var.role_names.ec2_role_key].name
}

resource "aws_launch_template" "strata" {
  name_prefix   = "strata-app-lt"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.launch_template.instance_type
  key_name = aws_key_pair.strata_key.key_name # Using same key for bastion and pvt server for now
  vpc_security_group_ids = [
    aws_security_group.strata_sg["ec2"].id
  ]
  iam_instance_profile {
    arn = aws_iam_instance_profile.strata.arn
  }

  # Configuring Volume
  block_device_mappings {
    # "/dev/xvda" is typically the root volume for Linux (use /dev/sda1 for Windows)
    device_name = "/dev/xvda"

    ebs {
      volume_size           =  var.launch_template.volume_size    # Size in GB
      volume_type           =  var.launch_template.volume_type # General Purpose SSD (gp3 is best practice)
      encrypted             =  var.launch_template.encrypted
      kms_key_id            =  aws_kms_key.strata.arn
      delete_on_termination = var.launch_template.deletion_on_termination   # Cleans up the disk when ASG terminates the instance
    }
  }
  
}

resource "aws_autoscaling_group" "strata" {
  name                      = "strata-asg-${var.env_tag}"
  max_size                  = var.asg.max_size
  min_size                  = var.asg.min_size
  health_check_grace_period = var.asg.health_check_grace_period
  health_check_type         = var.asg.health_check_type
  desired_capacity          = var.asg.desired_capacity
  launch_template {
    id      = aws_launch_template.strata.id
    version = "$Latest"
  }
  vpc_zone_identifier = [for subnet in aws_subnet.strata_private_subnet : subnet.id]

  instance_maintenance_policy {
    min_healthy_percentage = 90
    max_healthy_percentage = 120
  }

  timeouts {
    delete = var.asg.delete
  }

  #   dynamic "tag" {
  #     for_each = var.extra_tags
  #     content {
  #       key                 = tag.value.key
  #       propagate_at_launch = tag.value.propagate_at_launch
  #       value               = tag.value.value
  #     }
  #   }
}

resource "aws_autoscaling_attachment" "strata" {
  autoscaling_group_name = aws_autoscaling_group.strata.id
  lb_target_group_arn    = aws_lb_target_group.strata.arn
}