###
# Sets up Amazon SES for application mail. 
#
###

module "ses" {
  source  = "cloudposse/ses/aws"
  version = "0.22.1"

  domain           = var.domain
  zone_id          = var.zone_id
  verify_dkim      = var.verify_dkim
  verify_domain    = var.verify_domain
  ses_user_enabled = var.ses_user_enabled
  iam_permissions = [
    "ses:SendEmail",
    "ses:SendRawEmail"
  ]
  iam_allowed_resources  = ["*"]
  iam_access_key_max_age = var.iam_access_key_max_age
  ses_group_enabled      = false

  context = module.this.context
}

// Role to allow sending email via SES domain
module "send_email_role" {
  source  = "cloudposse/iam-role/aws"
  version = "0.14.1"

  context = module.this.context
  name    = "email"

  enabled = module.this.enabled && var.create_iam_role

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
      module.ses.ses_domain_identity_arn
    ]
  }
}


module "store_write" {
  source  = "cloudposse/ssm-parameter-store/aws"
  version = "0.8.4"

  enabled = module.this.enabled && var.iam_key_id_ssm_param_path != ""

  parameter_write = [
    {
      name        = var.iam_key_id_ssm_param_path
      value       = module.ses.access_key_id
      type        = "SecureString"
      overwrite   = "true"
      description = "${module.this.stage} SES user IAM key ID"
    },
    {
      name        = var.iam_key_secret_ssm_param_path
      value       = module.ses.secret_access_key
      type        = "SecureString"
      overwrite   = "true"
      description = "${module.this.stage} SES user IAM key secret"
    }
  ]

  context = module.this.context
}
