# VPC
resource "aws_vpc" "strata" {
  cidr_block           = local.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = local.tags
}

# Public Subnets
resource "aws_subnet" "strata_public_subnet" {
  for_each = var.public_subnets

  vpc_id            = aws_vpc.strata.id
  cidr_block        = each.value.cidr
  availability_zone = each.key


  tags = merge({ Name = "public-${each.key}" }, local.tags)
}

# Private Subnets
resource "aws_subnet" "strata_private_subnet" {
  for_each          = var.private_subnets
  vpc_id            = aws_vpc.strata.id
  cidr_block        = each.value.cidr
  availability_zone = each.key


  tags = merge({ Name = "public-${each.key}" }, local.tags)
}

# Data Subnets
resource "aws_subnet" "strata_data_subnet" {
  for_each          = var.data_subnets
  vpc_id            = aws_vpc.strata.id
  cidr_block        = each.value.cidr
  availability_zone = each.key


  tags = merge({ Name = "public-${each.key}" }, local.tags)
}

resource "aws_db_subnet_group" "strata_db_group" {
  name = "strata-db-subnet-group"

  # Fetches the IDs of data subnets from your existing subnet map
  subnet_ids = [for s in aws_subnet.strata_data_subnet : s.id]

  tags = {
    Name = "Strata DB Subnet Group"
  }
}

# IGW
resource "aws_internet_gateway" "strata" {
  vpc_id = aws_vpc.strata.id

  tags = try(local.tags, {})
}

# EIPs
resource "aws_eip" "strata" {
  for_each = toset(var.nat_gateway_azs)

  domain = "vpc"
  tags   = merge({ Name = "eip-${each.key}" }, local.tags)
}

# NAT GW
resource "aws_nat_gateway" "strata" {
  for_each = toset(var.nat_gateway_azs)

  allocation_id = aws_eip.strata[each.key].id
  subnet_id     = aws_subnet.strata_public_subnet[each.key].id

  tags = merge({ Name = "nat-${each.key}" }, local.tags)

  # To ensure proper ordering, it is recommended to add an explicit dependency on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.strata]
}

# Create NACL rules each for type of Subnets - Private, Public, Data - 3 NACL in total
resource "aws_network_acl" "strata_public" {
  vpc_id     = aws_vpc.strata.id
  subnet_ids = [for s in aws_subnet.strata_public_subnet : s.id]

  dynamic "ingress" {
    for_each = var.public_nacl_rules.ingress
    content {
      protocol   = ingress.value.protocol
      rule_no    = ingress.value.rule_no
      action     = ingress.value.action
      cidr_block = try(ingress.value.cidr_block, local.vpc_cidr)
      from_port  = ingress.value.from_port
      to_port    = ingress.value.to_port
    }
  }

  dynamic "egress" {
    for_each = var.public_nacl_rules.egress
    content {
      protocol   = egress.value.protocol
      rule_no    = egress.value.rule_no
      action     = egress.value.action
      cidr_block = egress.value.cidr_block
      from_port  = egress.value.from_port
      to_port    = egress.value.to_port
    }
  }

}

resource "aws_network_acl" "strata_private" {
  vpc_id = aws_vpc.strata.id
  # subnet_ids = [for s in aws_subnet.strata_private_subnet : s.id]

  dynamic "ingress" {
    for_each = var.private_nacl_rules.ingress
    content {
      protocol   = ingress.value.protocol
      rule_no    = ingress.value.rule_no
      action     = ingress.value.action
      cidr_block = try(ingress.value.cidr_block, local.vpc_cidr)
      from_port  = ingress.value.from_port
      to_port    = ingress.value.to_port
    }
  }

  dynamic "egress" {
    for_each = var.private_nacl_rules.egress
    content {
      protocol   = egress.value.protocol
      rule_no    = egress.value.rule_no
      action     = egress.value.action
      cidr_block = egress.value.cidr_block
      from_port  = egress.value.from_port
      to_port    = egress.value.to_port
    }
  }

}

resource "aws_network_acl" "strata_data" {
  vpc_id     = aws_vpc.strata.id
  subnet_ids = [for s in aws_subnet.strata_data_subnet : s.id]

  dynamic "ingress" {
    for_each = var.data_nacl_rules.ingress
    content {
      protocol   = ingress.value.protocol
      rule_no    = ingress.value.rule_no
      action     = ingress.value.action
      cidr_block = try(ingress.value.cidr_block, local.vpc_cidr)
      from_port  = ingress.value.from_port
      to_port    = ingress.value.to_port
    }
  }

  dynamic "egress" {
    for_each = var.data_nacl_rules.egress
    content {
      protocol   = egress.value.protocol
      rule_no    = egress.value.rule_no
      action     = egress.value.action
      cidr_block = egress.value.cidr_block
      from_port  = egress.value.from_port
      to_port    = egress.value.to_port
    }
  }

}

# Associate Public NACL to Public Subnets
resource "aws_network_acl_association" "strata_public" {
  for_each = var.public_subnets

  network_acl_id = aws_network_acl.strata_public.id
  subnet_id      = aws_subnet.strata_public_subnet[each.key].id
}

# Associate Private NACL to Private Subnets
resource "aws_network_acl_association" "strata_private" {
  for_each = var.private_subnets

  network_acl_id = aws_network_acl.strata_private.id
  subnet_id      = aws_subnet.strata_private_subnet[each.key].id
}

# Associate Data NACL to Data Subnets
resource "aws_network_acl_association" "strata_data" {
  for_each = var.data_subnets

  network_acl_id = aws_network_acl.strata_data.id
  subnet_id      = aws_subnet.strata_data_subnet[each.key].id
}