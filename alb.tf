resource "aws_lb" "strata" {
  for_each = var.lb

  name               = each.key
  internal           = each.value.internal
  load_balancer_type = each.value.load_balancer_type
  security_groups    = [aws_security_group.strata_sg[each.key].id]
  subnets            = [for subnet in aws_subnet.strata_public_subnet : subnet.id]

  enable_deletion_protection = each.value.enable_deletion_protection

  access_logs {
    bucket  = aws_s3_bucket.strata_bucket["strata_logging_bucket"].bucket
    prefix  = "alb-logs"
    enabled = true
  }

  tags = local.tags
}

resource "aws_lb_target_group" "strata" {
  for_each = var.target_group

  name        = each.key
  port        = each.value.port
  protocol    = each.value.protocol
  target_type = each.value.target_type
  vpc_id      = aws_vpc.strata.id

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
  for_each = var.target_group

  load_balancer_arn = aws_lb.strata[each.value.lb_key].arn
  port              = each.value.port
  protocol          = each.value.protocol
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.strata.certificate_arn

  default_action {
    type             = each.value.type
    target_group_arn = aws_lb_target_group.strata[each.key].arn
  }
}

# HTTP listener — redirects all port-80 traffic to HTTPS on the same port
resource "aws_lb_listener" "strata_http_redirect" {
  load_balancer_arn = aws_lb.strata["strataLB"].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
