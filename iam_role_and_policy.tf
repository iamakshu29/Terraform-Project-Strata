# The flow is:
# IAM Role — identity that your EC2/ECS assumes
# Trust policy — defines who can assume the role (EC2 service in this case)
# IAM Policy, which contains rules
# Policy attachment — attaches your policy (read_secrets_policy) to the role (strata_app)
# Instance profile — wraps the role, so EC2 can use it

resource "aws_iam_role" "strata_app" {
  for_each   = var.iam_policy
  name = each.key

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


data "aws_iam_policy_document" "policy" {
  dynamic "statement" {
    for_each = var.iam_policy

    content {
      sid       = statement.key
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}

# Create IAM policy, for allowing an EC2 instance, ECS task, or an application to read the secret credentials
resource "aws_iam_policy" "read_secrets_policy" {
  for_each   = var.iam_policy
  name        = "strata-read-db-secret-policy"
  description = "Allows reading the database secret string"
  policy = data.aws_iam_policy_document.policy.json
}


# Controls who can access the secret at the secret level
resource "aws_iam_role_policy_attachment" "read_secrets" {
  for_each   = var.iam_policy
  role       = each.key
  policy_arn = each.value
}

# Instance profile — required for EC2 to use the role
resource "aws_iam_instance_profile" "strata" {
  for_each = var.iam_policy
  name     = each.key
  role     = each.key
}

# On EC2 iam_instance_profile = aws_iam_instance_profile.strata_app.name