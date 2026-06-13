resource "aws_route_table" "strata_public" {
  vpc_id = local.vpc_cidr
}

resource "aws_route" "strata_public" {
  for_each = var.route.public_routes

  route_table_id         = aws_route_table.strata_public.id
  destination_cidr_block = each.value.destination_cidr
  gateway_id             = aws_internet_gateway.strata.id
}

resource "aws_route_table_association" "strata_public" {
  for_each       = var.public_subnets
  subnet_id      = each.key
  route_table_id = aws_route_table.strata_public.id
}



resource "aws_route_table" "strata_private" {
  vpc_id = local.vpc_cidr
}

resource "aws_route" "strata_private" {
  for_each = var.route.private_routes

  route_table_id         = aws_route_table.strata_private.id
  destination_cidr_block = each.value.destination_cidr

  # go to map az_to_nat and then get the key as the key matched with routes
  nat_gateway_id = aws_nat_gateway.strata[local.az_to_nat[each.key]].id
}

resource "aws_route_table_association" "strata_private" {
  for_each       = var.private_subnets
  subnet_id      = each.key
  route_table_id = aws_route_table.strata_private.id
}



resource "aws_route_table" "strata_data" {
  vpc_id = local.vpc_cidr
}

resource "aws_route" "strata_data" {
  for_each = var.route.data_routes

  route_table_id         = aws_route_table.strata_data.id
  destination_cidr_block = each.value.destination_cidr
  nat_gateway_id         = aws_nat_gateway.strata[local.az_to_nat[each.key]].id
}

resource "aws_route_table_association" "strata_data" {
  for_each       = var.data_subnets
  subnet_id      = each.key
  route_table_id = aws_route_table.strata_data.id
}