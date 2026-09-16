resource "aws_ssm_parameter" "strata_paramter_store" {
  for_each = local.parameters
  name     = each.key
  type     = "SecureString"
  key_id   = aws_kms_key.strata.arn
  value    = each.value
}