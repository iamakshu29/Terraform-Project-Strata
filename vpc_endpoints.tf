# Dedicated SG for interface endpoints — allows HTTPS from anywhere within the VPC
resource "aws_security_group" "vpc_endpoints" {
  name   = "vpc-endpoints-sg"
  vpc_id = aws_vpc.strata.id
  tags   = merge({ Name = "vpc-endpoints-sg" }, local.tags)
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoints_https" {
  security_group_id = aws_security_group.vpc_endpoints.id
  cidr_ipv4         = local.vpc_cidr
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "vpc_endpoints_all" {
  security_group_id = aws_security_group.vpc_endpoints.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# S3 Gateway endpoint — free, attaches to route tables instead of creating ENIs
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.strata.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    [aws_route_table.strata_public.id],
    [for rt in aws_route_table.strata_private : rt.id],
    [for rt in aws_route_table.strata_data : rt.id],
  )

  tags = merge({ Name = "endpoint-s3" }, local.tags)
}

# Interface endpoints — one ENI per private subnet, private DNS resolves service FQDNs to VPC IPs
resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoints

  vpc_id              = aws_vpc.strata.id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for s in aws_subnet.strata_private_subnet : s.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge({ Name = "endpoint-${each.key}" }, local.tags)
}
