resource "aws_lb" "strata" {
  name               = "strata-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.strata_sg["alb"].id]
  subnets            = [for subnet in aws_subnet.strata_public_subnet : subnet.id]

  enable_deletion_protection = true

  tags = local.tags
}

resource "aws_lb_target_group" "strata" {
  name     = "strata-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.strata.id
}
