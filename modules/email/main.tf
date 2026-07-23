###
# Sets up Amazon SES for application mail. 
#
###

module "ses" {
  source  = "cloudposse/ses/aws"
  version = "0.25.0"

  domain                             = var.domain
  zone_id                            = var.zone_id
  verify_dkim                        = var.verify_dkim
  verify_domain                      = var.verify_domain
  create_spf_record                  = var.create_spf_record
  custom_from_subdomain              = var.custom_from_subdomain
  custom_from_behavior_on_mx_failure = var.custom_from_behavior_on_mx_failure

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
  version = "0.13.0"

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

# Bounce and Complaints notification

resource "aws_ses_identity_notification_topic" "notification_topic" {
  for_each = module.this.enabled ? var.notification_emails : {}

  topic_arn                = module.email_notification_topic[each.key].sns_topic_arn
  notification_type        = title(each.key)
  identity                 = var.domain
  include_original_headers = true
}

module "email_notification_topic" {
  source  = "cloudposse/sns-topic/aws"
  version = "1.2.0"

  for_each = var.notification_emails

  name       = "ses"
  attributes = [each.key]

  encryption_enabled = false

  allowed_aws_services_for_sns_published = [
    "ses.amazonaws.com"
  ]

  subscribers = {
    email = {
      protocol               = "email-json"
      endpoint               = each.value
      endpoint_auto_confirms = false
      raw_message_delivery   = false
    }
  }

  context = module.this.context
}

# SES delivery-feedback webhook
#
# One SNS topic receives the domain identity's Bounce/Complaint/Delivery
# notifications for forwarding to an application HTTPS webhook, which validates
# the SNS signature and the topic ARN and confirms the subscription itself.
# include_original_headers keeps the correlation header the app reads to map a
# bounce back to the exact recipient and run.
#
# Topic creation is decoupled from the subscription so the module never forces a
# dependency cycle. Only the subscription needs the webhook URL; the topic and
# the SES notification wiring need just the topic ARN and the domain. A consumer
# whose webhook URL comes from a stack that depends on this one (e.g. their web
# module's ALB/CDN) sets webhook_topic_enabled, leaves webhook_notification_endpoint
# empty, reads ses_webhook_topic_arn, and owns the subscription in that stack.
# A consumer with a statically known URL passes it here and lets the module own
# the subscription too. endpoint_auto_confirms lets the subscription reconcile to
# "confirmed" once the app is live; a still-pending subscription does not fail the apply.

locals {
  webhook_topic_enabled        = module.this.enabled && (var.webhook_topic_enabled || var.webhook_notification_endpoint != "")
  webhook_subscription_enabled = local.webhook_topic_enabled && var.webhook_notification_endpoint != ""
}

module "ses_webhook_topic" {
  source  = "cloudposse/sns-topic/aws"
  version = "1.2.0"

  enabled = local.webhook_topic_enabled

  name       = "ses"
  attributes = ["webhook"]

  # SES cannot publish to a topic encrypted with the default aws/sns KMS key.
  encryption_enabled = false

  allowed_aws_services_for_sns_published = [
    "ses.amazonaws.com"
  ]

  subscribers = local.webhook_subscription_enabled ? {
    webhook = {
      protocol               = "https"
      endpoint               = var.webhook_notification_endpoint
      endpoint_auto_confirms = true
      raw_message_delivery   = false
    }
  } : {}

  context = module.this.context
}

resource "aws_ses_identity_notification_topic" "webhook" {
  for_each = local.webhook_topic_enabled ? toset(var.webhook_notification_types) : []

  topic_arn                = module.ses_webhook_topic.sns_topic_arn
  notification_type        = each.value
  identity                 = var.domain
  include_original_headers = true
}

# DMARC

resource "aws_route53_record" "amazonses_dmarc_record" {
  count = module.this.enabled && length(var.dmarc_record) > 0 ? 1 : 0

  zone_id = var.zone_id
  name    = "_dmarc.${var.domain}"
  type    = "TXT"
  ttl     = "1800"
  records = var.dmarc_record
}
