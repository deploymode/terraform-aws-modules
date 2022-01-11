###
# Sets up Amazon SES for application mail. 
#
###

module "ses" {
  source  = "cloudposse/ses/aws"
  version = "0.22.1"

  domain            = var.domain
  zone_id           = var.zone_id
  verify_dkim       = var.verify_dkim
  verify_domain     = var.verify_domain
  ses_user_enabled  = false
  ses_group_enabled = false

  context = module.this.context
}

// Role to allow sending email via SES domain
module "send_email_role" {
  source  = "cloudposse/iam-role/aws"
  version = "0.13.0"

  context = module.this.context
  name    = "email"

  enabled = module.this.enabled

  policy_document_count = 1

  policy_description = "Allow sending email"
  role_description   = "IAM role with send email permissions"

  # Roles allowed to assume role
  principals = {
    AWS = [
      "arn:aws:iam::${var.aws_account_id}:root"
    ]
  }

  policy_documents = [
    data.aws_iam_policy_document.send_email_policy.json
  ]
}

data "aws_iam_policy_document" "send_email_policy" {
  statement {
    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail"
    ]

    resources = [
      "*"
    ]
  }
}
