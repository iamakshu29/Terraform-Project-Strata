resource "aws_ssm_parameter" "strata_paramter_store" {
  for_each = local.parameters
  name     = each.key
  type     = "SecureString"
  key_id   = var.kms_key_arn
  value    = each.value
}