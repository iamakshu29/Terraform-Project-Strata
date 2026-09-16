# Networking
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.strata.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs keyed by availability zone"
  value       = { for key, subnet in aws_subnet.strata_public_subnet : key => subnet.id }
}

output "private_subnet_ids" {
  value = { for key, subnet in aws_subnet.strata_private_subnet : key => subnet.id }
}

output "data_subnet_ids" {
  value = { for key, subnet in aws_subnet.strata_data_subnet : key => subnet.id }
}

output "db_subnet_group_name" {
  value = aws_db_subnet_group.strata_db_group.name
}