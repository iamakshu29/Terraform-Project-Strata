locals {
  tags = {
    Project     = "Strata"
    Environment = var.env_tag
  }

  # Flattens var.iam_policy into a single map keyed by "role-policy" for for_each
  policies = merge([
    for role_name, policy in var.iam_policy : {
      for policy_name, policy_element in policy :
      "${role_name}-${policy_name}" => {
        role_name       = role_name
        policy_name     = policy_name
        policy_elements = policy_element
      }
    }
  ]...)
}
