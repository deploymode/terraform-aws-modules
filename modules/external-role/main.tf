###
# Sets up an IAM role for external access.
#
###

module "role" {
  source  = "cloudposse/iam-role/aws"
  version = "0.18.0"

  principals = {
    "AWS" : [var.aws_account_id]
  }
  use_fullname = false

  managed_policy_arns = compact(concat(
    var.policy_arns,
  formatlist("arn:aws:iam::aws:policy/%s", var.aws_managed_policy_names)))
  policy_document_count = 0

  policy_description = "External access policy providing read only access"
  role_description   = "External access role for account id ${var.aws_account_id}"

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
