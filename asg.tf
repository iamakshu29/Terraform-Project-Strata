resource "aws_launch_template" "strata" {
  name_prefix   = "foobar"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.launch_template.instance_type
  vpc_security_group_ids = [
    aws_security_group.strata_sg["ec2"].id
  ]
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
  vpc_zone_identifier = [for subnet in aws_subnet.strata_public_subnet : subnet.id]

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