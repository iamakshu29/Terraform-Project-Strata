# The flow is:
# IAM Role — identity that your EC2/ECS assumes
# Trust policy — defines who can assume the role (EC2 service in this case)
# IAM Policy, which contains rules/permission
# Policy attachment — attaches your policy (read_secrets_policy) to the role role_ecs_task, ...
# Instance profile — wraps the role, so EC2 can use it
# policy_document -> policy -> role -> policy_attachment (to attach that policy to a role) -> add the role to a resource 

# NEEDS REWORK

data "aws_iam_policy_document" "policy" {
  for_each = local.policies
  statement {
    sid       = each.value.policy_elements.sid
    effect    = each.value.policy_elements.effect
    actions   = each.value.policy_elements.actions
    resources = each.value.policy_elements.resources
  }
}

# Create IAM policy, for allowing an EC2 instance, ECS task, or an application to read the secret credentials
resource "aws_iam_policy" "strata_policy" {
  for_each = local.policies
  name     = "strata-${each.value.policy_name}"
  policy   = data.aws_iam_policy_document.policy[each.key].json # need to check this
}

resource "aws_iam_role" "strata" {
  for_each = var.assume_role_policy
  name     = each.key

  assume_role_policy = jsonencode({
    Version = each.value.Version
    Statement = [
      {
        Action = each.value.Action
        Effect = each.value.Effect
        Sid    = each.value.Sid
        Principal = {
          Service = each.value.Principal_Service
        }
      },
    ]
  })

  tags = merge({ Name = each.key }, local.tags)
}

# Controls who can access the secret at the secret level
resource "aws_iam_role_policy_attachment" "strata_attach_policy" {
  for_each   = local.policies
  role       = aws_iam_role.strata[each.value.role_name].name
  policy_arn = aws_iam_policy.strata_policy[each.key].arn
}

# Grants EC2 instances and ASG nodes the SSM Session Manager permissions
resource "aws_iam_role_policy_attachment" "strata_ssm_core" {
  role       = aws_iam_role.strata[var.role_names.ec2_role_key].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}