resource "aws_security_group" "strata_sg" {
  for_each    = var.security_group
  name        = "${each.key}-sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.strata.id

  tags = {
    Name = "allow_tls"
  }
}

locals {
  ingress_rules = merge([
    for sg_name, sg in var.security_group : {
      for rule_name, rule in sg.ingress :
      "${sg_name}-${rule_name}" => {
        sg_name = sg_name
        rule    = rule
      }
    }
  ]...)
}

# {
#   "alb-https" = {
#     sg_name = "alb"
#     rule = {
#       cidr_ipv4   = "0.0.0.0/0"
#       from_port   = 443
#       to_port     = 443
#       ip_protocol = "tcp"
#     }
#   }
# }

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4_strata_server_rule" {
  for_each = local.ingress_rules

  security_group_id            = aws_security_group.strata_sg[each.value.sg_name].id
  referenced_security_group_id = try(each.value.rule.source_security_group, null)

  cidr_ipv4   = try(each.value.rule.cidr_ipv4, null)
  from_port   = each.value.rule.from_port
  ip_protocol = each.value.rule.ip_protocol
  to_port     = each.value.rule.to_port
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_strata_server_rule" {
  for_each = var.security_group

  security_group_id = aws_security_group.strata_sg[each.key].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}