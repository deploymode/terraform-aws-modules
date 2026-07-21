data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Terraform-managed Betterstack CloudWatch integration. Requires the
# BETTERUPTIME_API_TOKEN environment variable at plan/apply time.
resource "betteruptime_aws_cloudwatch_integration" "this" {
  count = module.this.enabled && var.betterstack_enabled ? 1 : 0

  name            = module.this.id
  policy_id       = var.betterstack_policy_id
  recovery_period = var.betterstack_recovery_period
}

# Fallback for a webhook created outside Terraform: the URL carries an ingest
# token, so it is read from SSM (seeded out-of-band) rather than passed as a
# plain input that would sit in git.
data "aws_ssm_parameter" "webhook_url" {
  count = module.this.enabled && !var.betterstack_enabled && var.webhook_url_ssm_param != "" ? 1 : 0

  name            = var.webhook_url_ssm_param
  with_decryption = true
}

locals {
  webhook_subscribed = module.this.enabled && (var.betterstack_enabled || var.webhook_url_ssm_param != "")
  webhook_url        = var.betterstack_enabled ? try(betteruptime_aws_cloudwatch_integration.this[0].webhook_url, null) : try(data.aws_ssm_parameter.webhook_url[0].value, null)
}

resource "aws_sns_topic" "alarms" {
  count = module.this.enabled ? 1 : 0

  name = module.this.id
  tags = module.this.tags
}

resource "aws_sns_topic_policy" "alarms" {
  count = module.this.enabled ? 1 : 0

  arn = aws_sns_topic.alarms[0].arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudWatchAlarmsPublish"
        Effect    = "Allow"
        Principal = { Service = "cloudwatch.amazonaws.com" }
        Action    = "SNS:Publish"
        Resource  = aws_sns_topic.alarms[0].arn
        Condition = {
          StringEquals = { "AWS:SourceAccount" = data.aws_caller_identity.current.account_id }
          ArnLike      = { "AWS:SourceArn" = "arn:aws:cloudwatch:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:alarm:*" }
        }
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "webhook" {
  count = local.webhook_subscribed ? 1 : 0

  topic_arn              = aws_sns_topic.alarms[0].arn
  protocol               = "https"
  endpoint               = local.webhook_url
  endpoint_auto_confirms = true
}

resource "aws_sns_topic_subscription" "email" {
  for_each = module.this.enabled ? toset(var.notification_emails) : toset([])

  topic_arn = aws_sns_topic.alarms[0].arn
  protocol  = "email"
  endpoint  = each.value
}
