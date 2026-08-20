# Public Route Table — one shared table, one 0.0.0.0/0 → IGW route for all public subnets

resource "aws_route_table" "strata_public" {
  vpc_id = aws_vpc.strata.id
  tags   = merge({ Name = "public-rt" }, local.tags)
}

resource "aws_route" "strata_public" {
  for_each = var.route.public_routes

  route_table_id         = aws_route_table.strata_public.id
  destination_cidr_block = each.value.destination_cidr
  gateway_id             = aws_internet_gateway.strata.id
}

resource "aws_route_table_association" "strata_public" {
  for_each       = var.public_subnets
  subnet_id      = aws_subnet.strata_public_subnet[each.key].id
  route_table_id = aws_route_table.strata_public.id
}

# Private Route Tables — one per AZ so each AZ routes through its own NAT GW.
# ap-south-1c shares ap-south-1b's NAT GW (see az_to_nat in locals.tf).

resource "aws_route_table" "strata_private" {
  for_each = var.private_subnets
  vpc_id   = aws_vpc.strata.id
  tags     = merge({ Name = "private-rt-${each.key}" }, local.tags)
}

resource "aws_route" "strata_private" {
  for_each = var.private_subnets

  route_table_id         = aws_route_table.strata_private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.strata[local.az_to_nat[each.key]].id
}

resource "aws_route_table_association" "strata_private" {
  for_each       = var.private_subnets
  subnet_id      = aws_subnet.strata_private_subnet[each.key].id
  route_table_id = aws_route_table.strata_private[each.key].id
}

# Data Route Tables — one per AZ, no internet route (data tier is fully isolated).

resource "aws_route_table" "strata_data" {
  for_each = var.data_subnets
  vpc_id   = aws_vpc.strata.id
  tags     = merge({ Name = "data-rt-${each.key}" }, local.tags)
}

resource "aws_route_table_association" "strata_data" {
  for_each       = var.data_subnets
  subnet_id      = aws_subnet.strata_data_subnet[each.key].id
  route_table_id = aws_route_table.strata_data[each.key].id
}