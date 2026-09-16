resource "aws_lb" "strata" {
  for_each = var.lb

  name               = each.key
  internal           = each.value.internal
  load_balancer_type = each.value.load_balancer_type
  security_groups    = [var.security_group_ids[each.key]]
  subnets            = values(var.public_subnet_ids)

  enable_deletion_protection = each.value.enable_deletion_protection

  access_logs {
    bucket  = var.logging_bucket_name
    prefix  = "alb-logs"
    enabled = true
  }

  tags = merge({ Name = "${each.key}-${var.env_tag}" }, local.tags)
}

resource "aws_lb_target_group" "strata" {
  for_each = var.target_group

  name        = each.key
  port        = each.value.port
  protocol    = each.value.protocol
  target_type = each.value.target_type
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = each.value.protocol
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200-299"
  }
}

# HTTPS listeners — one per target group (port 8443 for ASG, port 8442 for ECS)
resource "aws_lb_listener" "strata_https" {
  for_each = var.lb

  load_balancer_arn = aws_lb.strata[each.key].arn
  port              = each.value.port
  protocol          = each.value.protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.strata["strataInstance"].arn
  }
}

# Routes /api/* to ECS — ensures strataECS TG is attached to the ALB (required by ECS service)
resource "aws_lb_listener_rule" "strata_ecs" {
  listener_arn = aws_lb_listener.strata_https["strataLB"].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.strata["strataECS"].arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

# HTTP listener — redirects all port-80 traffic to HTTPS on the same port
## NOTE - uncomment when you have a valid certificate else both listeners will have a port-conflict.
# resource "aws_lb_listener" "strata_http_redirect" {
#   load_balancer_arn = aws_lb.strata["strataLB"].arn
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     type = "redirect"

#     redirect {
#       port        = "443"
#       protocol    = "HTTPS"
#       status_code = "HTTP_301"
#     }
#   }
# }
