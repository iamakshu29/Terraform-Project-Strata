locals {

  result = merge([
        for res_name, policy in var.iam_policy : {
            for policy_name, policy_type in policy:
            "${res_name}-${policy_name}" => {
                policy_type = policy_type
            }
        }
    ]...)
}
