###
# Sets up an IAM role for external access.
#
###

module "role" {
  source  = "cloudposse/iam-role/aws"
  version = "0.21.0"

  attributes = ["external", "role"]

  principals = {
    "AWS" : [var.aws_account_id]
  }
  use_fullname = true

  managed_policy_arns = compact(concat(
    var.policy_arns,
    formatlist("arn:aws:iam::aws:policy/%s", var.aws_managed_policy_names)
  ))

  policy_documents = length(var.policy_documents) > 0 ? [for policy, policy_data in module.inline_policies : policy_data.json] : []

  policy_description = "External access policy providing read only access for ${module.this.name}"
  role_description   = "External access role for account id ${var.aws_account_id} for ${module.this.name}"

  assume_role_conditions = [
    {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values = [
        var.external_id
      ]
    }
  ]

  context = module.this.context
}

module "inline_policies" {
  source  = "cloudposse/iam-policy/aws"
  version = "2.0.1"

  for_each = var.policy_documents

  name = each.key

  iam_policy = each.value

  context = module.this.context
}