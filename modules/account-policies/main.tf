
module "iam_policy" {
  source  = "cloudposse/iam-policy/aws"
  version = "0.4.0"

  for_each = var.policies

  name = each.key

  iam_policy_statements = each.value

  iam_policy_enabled = true

  context = module.this.context
}
