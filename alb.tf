resource "aws_lb" "strata" {
  for_each = var.lb

  name               = each.key
  internal           = each.value.internal
  load_balancer_type = each.value.load_balancer_type
  security_groups    = [aws_security_group.strata_sg[each.key].id]
  subnets            = [for subnet in aws_subnet.strata_public_subnet : subnet.id]

  enable_deletion_protection = each.value.enable_deletion_protection

  tags = local.tags
}

resource "aws_lb_target_group" "strata" {
  for_each = var.target_group

  name        = each.key
  port        = each.value.port
  protocol    = each.value.protocol
  target_type = each.value.target_type
  vpc_id      = aws_vpc.strata.id
}

resource "aws_lb_listener" "strata" {
  for_each = var.target_group

  # Pulls the correct Load Balancer using the lb_key from your map
  load_balancer_arn = aws_lb.strata[each.value.lb_key].arn
  
  port              = each.value.port
  protocol          = each.value.protocol
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  # No dynamic block needed! Each listener gets exactly ONE default_action
  default_action {
    type             = each.value.type
    target_group_arn = aws_lb_target_group.strata[each.key].arn
  }
}