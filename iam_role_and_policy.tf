# The flow is:
# IAM Role — identity that your EC2/ECS assumes
# Trust policy — defines who can assume the role (EC2 service in this case)
# IAM Policy, which contains rules
# Policy attachment — attaches your policy (read_secrets_policy) to the role (strata_app)
# Instance profile — wraps the role, so EC2 can use it

resource "aws_iam_role" "strata_app" {
  for_each = var.iam_policy
  name     = each.key

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = local.tags
}

locals {
  policies = merge([
        for res_name, policy in var.iam_policy : {
            for policy_name, policy_type in policy:
            "${res_name}-${policy_name}" => {
                policy_name = policy_name
                policy_type = policy_type
            }
        }
    ]...)
}

data "aws_iam_policy_document" "policy" {
  for_each = local.policies
  statement {
    sid       = each.value.policy_type.sid
    effect    = each.value.policy_type.effect
    actions   = each.value.policy_type.actions
    resources = each.value.policy_type.resources
  }
}

# Create IAM policy, for allowing an EC2 instance, ECS task, or an application to read the secret credentials
resource "aws_iam_policy" "strata_policy" {
  for_each    = local.policies
  name        = "strata-${each.value.policy_name}"
  policy      = data.aws_iam_policy_document.policy[each.key].json
}


# Controls who can access the secret at the secret level
resource "aws_iam_role_policy_attachment" "strata-attach-policy" {
  for_each = local.policies
  role       = each.key
  policy_arn = aws_iam_policy.strata_policy[each.key].arn
}

# Instance profile — required for EC2 to use the role
# resource "aws_iam_instance_profile" "strata" {
#   name     = "ec2-polcy"
#   role     = aws_iam_policy.strata_policy[].arn
# }

# On EC2 iam_instance_profile = aws_iam_instance_profile.strata_app.name