# ECS Scheduled Task using EventBridge

locals {
  schedule_enabled = module.this.enabled && var.schedule_expression != null && var.schedule_expression != ""
}

module "schedule_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = ["scheduled-task"]
  enabled    = local.schedule_enabled
  context    = module.this.context
}

resource "aws_iam_role" "scheduler" {
  name = module.schedule_label.id

  count = local.schedule_enabled ? 1 : 0

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = ["scheduler.amazonaws.com"]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "scheduler" {

  count = local.schedule_enabled ? 1 : 0

  policy_arn = join("", aws_iam_policy.scheduler[*].arn)
  role       = join("", aws_iam_role.scheduler[*].name)
}

resource "aws_iam_policy" "scheduler" {
  name = module.schedule_label.id

  count = local.schedule_enabled ? 1 : 0

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # allow scheduler to execute the task
        Effect = "Allow",
        Action = [
          "ecs:RunTask"
        ]
        Resource = [module.ecs_task.task_definition_arn_without_revision]
      },
      { # allow scheduler to set the IAM roles of your task
        Effect = "Allow",
        Action = [
          "iam:PassRole"
        ]
        Resource = [module.ecs_task.task_role_arn, module.ecs_task.task_exec_role_arn]
      },
    ]
  })
}

resource "aws_scheduler_schedule" "scheduled_task" {
  name = module.schedule_label.id

  count = local.schedule_enabled ? 1 : 0

  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = var.schedule_expression
  schedule_expression_timezone = var.schedule_expression_timezone

  target {
    arn = var.ecs_cluster_arn
    # role that allows scheduler to start the task
    role_arn = join("", aws_iam_role.scheduler[*].arn)

    ecs_parameters {
      # schedule always uses latest revision
      task_definition_arn = module.ecs_task.task_definition_arn_without_revision
      launch_type         = var.ecs_launch_type
      dynamic "capacity_provider_strategy" {
        for_each = var.ecs_capacity_provider_strategies

        content {
          base              = capacity_provider_strategy.value.base
          capacity_provider = capacity_provider_strategy.value.capacity_provider
          weight            = capacity_provider_strategy.value.weight
        }
      }


      network_configuration {
        assign_public_ip = var.assign_public_ip
        security_groups  = var.ecs_security_group_ids
        subnets          = var.subnet_ids
      }

      propagate_tags = "TASK_DEFINITION"
    }

    retry_policy {
      maximum_event_age_in_seconds = 600
      maximum_retry_attempts       = 5
    }
  }
}
