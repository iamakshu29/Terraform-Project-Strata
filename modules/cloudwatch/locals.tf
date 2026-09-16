locals {
  tags = {
    Project     = "Strata"
    Environment = var.env_tag
  }

  dimension_value_to_arn = var.dimension_value_to_arn
}
