resource "aws_security_group" "strata_sg" {
  for_each    = var.security_group
  name        = "${each.key}-sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.strata.id

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4_strata_server_rule" {
  for_each = var.security_group

  security_group_id            = aws_security_group.strata_sg[each.key].id
  referenced_security_group_id = each.value.source_security_group_id

  cidr_ipv4   = each.value.vpc_cidr
  from_port   = each.value.from_port
  ip_protocol = each.value.ip_protocol
  to_port     = each.value.to_port
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_strata_server_rule" {
  for_each = var.security_group

  security_group_id = aws_security_group.strata_sg[each.key].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}