# Additional ECS event logging

locals {
    ecs_event_logs_enabled = module.this.enabled && length(var.ecs_event_logs) > 0
}

module "ecs_event_logs_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = ["ecs", "events"]
  enabled    = local.ecs_event_logs_enabled
  context    = module.this.context
}

# Log group
module "ecs_event_logs" {
  source  = "cloudposse/cloudwatch-logs/aws"
  version = "0.6.9"

  for_each = var.ecs_event_logs 

  enabled = module.this.enabled && each.value.enabled

  name = each.key

  iam_role_enabled = true
  principals = {
    Service = [
      "events.amazonaws.com",
      "delivery.logs.amazonaws.com"
    ]
  }

  retention_in_days = each.value.retention_in_days

  context = module.ecs_event_logs_label.context
}

# EventBridge rule

module "ecs_event_logs_cloudwatch_event" {
  source = "cloudposse/cloudwatch-events/aws"
  version = "0.9.0"

  for_each = var.ecs_event_logs

  name = each.key

  enabled = module.this.enabled && each.value.enabled

  cloudwatch_event_rule_description = each.key
  cloudwatch_event_rule_pattern = {
    source      = ["aws.ecs"]
    detail-type = [each.value.detail_type]
    detail = each.value.detail
  }
  cloudwatch_event_target_arn = module.ecs_event_logs[each.key].log_group_arn

  context = module.ecs_event_logs_label.context
}

# Allow EventBridge to write to the log group
# module "ecs_event_logs_iam_policy" {
#   source  = "cloudposse/iam-policy/aws"
#   version = "2.0.2"

#   enabled = local.ecs_event_logs_enabled 

#   name = "ecs-eventbridge-logs"

#   # Actually create the policy
#   iam_policy_enabled = true

#   iam_policy = [{
#     version   = "2012-10-17"
#     policy_id = "ecs-eventbridge-logs"
#     statements = [
#       {
#         sid = "AllowEventBridgeToWriteLogs"
#         effect = "Allow"
#         actions = [
#           "logs:CreateLogStream",
#           "logs:PutLogEvents",
#         ]
#         principal = {
#           Service = [
#             "events.amazonaws.com",
#             "delivery.logs.amazonaws.com"
#           ]
#         }
#         resources = [for log_group in module.ecs_event_logs : "${log_group.log_group_arn}:*"]
#       },

#     ]
#   }]

#   context = module.ecs_event_logs_label.context
# }

