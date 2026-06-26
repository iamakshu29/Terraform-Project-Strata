locals {
  parameters = {
    "/${var.env_tag}/app/db/endpoint" = aws_db_instance.strata_db.endpoint
    "/${var.env_tag}/app/s3/endpoint" = aws_s3_bucket.strata_bucket["strata_bucket"].bucket
    "/${var.env_tag}/app/s3_logging/endpoint" = aws_s3_bucket.strata_bucket["strata_logging_bucket"].bucket
    # "/${var.env_tag}/app/redis/endpoint" = 
    "/${var.env_tag}/app/service/endpoint" = aws_lb.strata["strataLB"].dns_name
  }
}

resource "aws_ssm_parameter" "strata_paramter_store" {
  for_each = local.parameters
  name     = each.key
  type     = "String"
  value    = each.value
}