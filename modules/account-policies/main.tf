
module "iam_policy" {
  source  = "cloudposse/iam-policy/aws"
  version = "2.0.1"

  for_each = var.policies

  name = each.key

  iam_policy_statements = each.value

  iam_policy_enabled = true

  context = module.this.context
}
