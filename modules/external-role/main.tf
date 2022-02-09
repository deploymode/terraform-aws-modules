###
# Sets up an IAM role for external access.
#
###

data "aws_iam_policy_document" "read_only" {
  arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "read_only_kinesis" {
  arn = "arn:aws:iam::aws:policy/AmazonKinesisReadOnlyAccess"
}

module "role" {
  source  = "cloudposse/iam-role/aws"
  version = "0.15.0"

  principals = {
    "AWS" : [var.aws_account_id]
  }
  use_fullname = false

  policy_documents = [
    data.aws_iam_policy_document.read_only.json,
    data.aws_iam_policy_document.read_only_kinesis.json
  ]

  policy_document_count = 2
  policy_description    = "External access policy providing read only access"
  role_description      = "External access role for account id ${var.aws_account_id}"

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
