# Instance profile — required for EC2 to use the role
resource "aws_iam_instance_profile" "strata" {
  name = "my-ec2-instance-profile"
  role = aws_iam_role.strata[var.role_names.ec2_role_key].name
}

resource "aws_launch_template" "strata" {
  name_prefix   = "strata-app-lt"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.launch_template.instance_type
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
      volume_size           = var.launch_template.volume_size # Size in GB
      volume_type           = var.launch_template.volume_type # General Purpose SSD (gp3 is best practice)
      encrypted             = var.launch_template.encrypted
      kms_key_id            = aws_kms_key.strata.arn
      delete_on_termination = var.launch_template.deletion_on_termination # Cleans up the disk when ASG terminates the instance
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
  target_group_arns         = [aws_lb_target_group.strata["strataInstance"].arn]
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

  dynamic "tag" {
    for_each = merge({ Name = "strata-asg-instance" }, local.tags)
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# Scale out/in based on average ALB request count per instance.
# AWS recommends this metric over CPU for web-tier ASGs.
resource "aws_autoscaling_policy" "strata_target_tracking" {
  name                   = "strata-alb-request-count-policy"
  autoscaling_group_name = aws_autoscaling_group.strata.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.strata["strataLB"].arn_suffix}/${aws_lb_target_group.strata["strataInstance"].arn_suffix}"
    }
    # Scale out when avg request count per instance exceeds 1000 req/min
    target_value = 1000.0
  }

  depends_on = [
    aws_lb_listener.strata_https
  ]
}
