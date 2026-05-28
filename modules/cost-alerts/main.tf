# ---- Anomaly detection ---------------------------------------------------

resource "aws_sns_topic" "anomaly_alerts" {
  count = module.this.enabled ? 1 : 0

  name = "${module.this.id}-anomaly"
  tags = module.this.tags
}

resource "aws_sns_topic_policy" "anomaly_alerts" {
  count = module.this.enabled ? 1 : 0

  arn = aws_sns_topic.anomaly_alerts[0].arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCostExplorerPublish"
        Effect    = "Allow"
        Principal = { Service = "costalerts.amazonaws.com" }
        Action    = "SNS:Publish"
        Resource  = aws_sns_topic.anomaly_alerts[0].arn
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "anomaly_email" {
  for_each = module.this.enabled ? toset(var.notification_emails) : toset([])

  topic_arn = aws_sns_topic.anomaly_alerts[0].arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_ce_anomaly_monitor" "service" {
  count = module.this.enabled ? 1 : 0

  name              = module.this.id
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"

  tags = module.this.tags
}

resource "aws_ce_anomaly_subscription" "alerts" {
  count = module.this.enabled ? 1 : 0

  name      = module.this.id
  frequency = "IMMEDIATE"

  monitor_arn_list = [
    aws_ce_anomaly_monitor.service[0].arn,
  ]

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      values        = [tostring(var.anomaly_threshold_usd)]
      match_options = ["GREATER_THAN_OR_EQUAL"]
    }
  }

  subscriber {
    type    = "SNS"
    address = aws_sns_topic.anomaly_alerts[0].arn
  }

  tags = module.this.tags
}

# ---- Daily budgets -------------------------------------------------------

module "budget_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  for_each = module.this.enabled ? var.budgets : {}

  attributes = [each.key]
  context    = module.this.context
}

resource "aws_budgets_budget" "daily" {
  for_each = module.this.enabled ? var.budgets : {}

  name         = module.budget_label[each.key].id
  budget_type  = "COST"
  limit_amount = each.value.limit_amount
  limit_unit   = "USD"
  time_unit    = "DAILY"

  cost_filter {
    name   = "LinkedAccount"
    values = [each.value.linked_account_id]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.notification_emails
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.notification_emails
  }

  tags = module.budget_label[each.key].tags
}
