locals {

  default_queue_name = "app"

  codepipeline_enabled = module.this.enabled && var.codepipeline_enabled

  ecr_enabled = module.this.enabled && var.container_image == null

  codepipeline_group_events_map = {
    all = [
      "failed",
      "canceled",
      "started",
      "resumed",
      "succeeded",
      "superseded"
    ]
    errors = [
      "failed",
    ]
    minimal = [
      "failed",
      "succeeded",
    ]
  }

  log_groups = {
    ecs = "/ecs/${module.container_label.id}"
  }

  build_log_groups = local.codepipeline_enabled ? {
    codebuild = "/aws/codebuild/${module.this.id}-build"
  } : {}

  queue_in_use = length(var.queue_names) > 0

  queue_env_vars = local.queue_in_use ? concat([
    {
      name  = "QUEUE_CONNECTION"
      value = "sqs"
    },
    {
      name  = "SQS_QUEUE"
      value = var.queue_names[local.default_queue_name]
    },
    {
      name  = "SQS_REGION"
      value = var.aws_region
    },
    {
      name  = "SQS_PREFIX"
      value = "https://sqs.${var.aws_region}.amazonaws.com/${var.aws_account_id}"
    }
    ],
    [
      for queue_short_name, queue_name in var.queue_names : {
        name  = join("_", ["SQS_QUEUE", upper(queue_short_name)])
        value = queue_name
  } if queue_short_name != local.default_queue_name]) : []
}

// ECR Registry/Repo
module "ecr" {
  source  = "cloudposse/ecr/aws"
  version = "0.42.1"

  enabled = local.ecr_enabled

  use_fullname         = true
  scan_images_on_push  = true
  max_image_count      = var.ecr_max_image_count
  image_tag_mutability = var.ecr_image_tag_mutability

  force_delete = var.ecr_force_delete

  context = module.this.context
}

// Container Defs
module "container_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"
  context = module.this.context
}

module "container" {
  source  = "cloudposse/ecs-container-definition/aws"
  version = "0.61.2"

  container_name               = module.container_label.id
  container_image              = var.container_image == null ? join(":", [module.ecr.repository_url, "latest"]) : var.container_image
  container_memory             = var.container_memory
  container_memory_reservation = var.container_memory_reservation
  container_cpu                = var.container_cpu
  start_timeout                = var.container_start_timeout
  stop_timeout                 = var.container_stop_timeout
  essential                    = true

  container_definition = var.container_overrides

  healthcheck = var.container_healthcheck

  readonly_root_filesystem = false

  environment = concat(
    [
      {
        name  = "STAGE"
        value = module.this.stage
      },
      {
        name  = "ENVIRONMENT"
        value = module.this.environment
      },
    ],
    var.container_environment,
    local.queue_env_vars
  )
  secrets       = var.container_ssm_secrets
  port_mappings = var.container_port_mappings
  command       = var.container_command
  entrypoint    = var.container_entrypoint

  log_configuration = {
    "logDriver" : var.log_driver,
    "secretOptions" : null,
    "options" : {
      "awslogs-group" : local.log_groups.ecs,
      "awslogs-region" : var.aws_region,
      "awslogs-stream-prefix" : "ecs",
      "awslogs-create-group" : "true"
    }
  }
}

module "ecs_task" {
  source  = "cloudposse/ecs-alb-service-task/aws"
  version = "0.78.0"

  context = module.this.context

  ecs_service_enabled          = var.ecs_service_enabled
  container_definition_json    = "[${module.container.json_map_encoded}]"
  ecs_cluster_arn              = var.ecs_cluster_arn
  capacity_provider_strategies = var.ecs_capacity_provider_strategies
  launch_type                  = var.ecs_launch_type
  platform_version             = var.ecs_platform_version
  vpc_id                       = var.vpc_id
  exec_enabled                 = var.ecs_enable_exec
  force_new_deployment         = var.service_force_new_deployment
  redeploy_on_apply            = var.service_redeploy_on_apply
  track_latest                 = var.ecs_task_def_track_latest

  service_registries = var.use_service_discovery == false ? [] : [
    {
      registry_arn   = join("", aws_service_discovery_service.service_discovery.*.arn)
      port           = 0 # only required for SRV records
      container_name = module.container_label.id
      container_port = 0 # var.container_port
    }
  ]

  # Additional security groups to assign to service
  security_group_ids             = var.ecs_security_group_ids
  subnet_ids                     = var.subnet_ids
  task_policy_arns_map           = var.ecs_task_policy_arns
  assign_public_ip               = var.assign_public_ip
  enable_icmp_rule               = false
  tags                           = var.tags
  ignore_changes_task_definition = var.ecs_ignore_changes_task_definition

  network_mode   = var.ecs_network_mode
  container_port = var.container_port

  propagate_tags = "TASK_DEFINITION"
  # deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  # deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_controller_type         = "ECS"
  circuit_breaker_deployment_enabled = var.ecs_circuit_breaker_deployment_enabled
  circuit_breaker_rollback_enabled   = var.ecs_circuit_breaker_rollback_enabled

  desired_count = var.ecs_task_desired_count
  task_memory   = var.ecs_task_memory
  task_cpu      = var.ecs_task_cpu
}

//////////
// Optional policy to allow external running of this task definition
// Intended to be attached to a role created outside this module
//////////

// IAM policy to allow running the task via RunTask on the specified cluster
module "ecs_task_run_policy" {
  source  = "cloudposse/iam-policy/aws"
  version = "2.0.2"

  enabled = module.this.enabled && var.create_run_task_role

  attributes = ["task", "run", "policy"]

  # Create the policy
  iam_policy_enabled = true

  iam_policy = [{
    version   = "2012-10-17"
    policy_id = "ecs-task-run-policy"
    statements = [
      {
        sid     = "PassRole"
        effect  = "Allow"
        actions = ["iam:PassRole"]
        resources = [
          module.ecs_task.task_exec_role_arn,
          module.ecs_task.task_role_arn
        ]
      },
      {
        sid       = "RunTask"
        effect    = "Allow"
        actions   = ["ecs:RunTask"]
        resources = ["${module.ecs_task.task_definition_arn_without_revision}:*"]
        conditions = [{
          test     = "ArnEquals"
          variable = "ecs:cluster"
          values   = [var.ecs_cluster_arn]
        }]
      },
      {
        sid       = "StopTask"
        effect    = "Allow"
        actions   = ["ecs:StopTask"]
        resources = ["${replace(var.ecs_cluster_arn, ":cluster/", ":task/")}/*"]
        conditions = [{
          test     = "ArnEquals"
          variable = "ecs:cluster"
          values   = [var.ecs_cluster_arn]
        }]
      }
    ]
  }]

  context = module.this.context
}

// Auto-scaling based on SQS queue metrics
//
// Queues are served by fixed per-task process pools, so a single fleet-wide
// capacity number would hide a drowning pool behind an idle one. The signal
// is therefore per-queue: weighted backlog divided by the slots that can
// actually drain that queue (running tasks * queue_processes[queue]), and
// the alarm scales on the WORST queue (MAX). Every queue in queue_names
// participates at queue_weight_default; queue_weights overrides exceptions.
// The scale-down signal additionally counts in-flight (not-visible) messages
// on the queues named in scale_in_inflight_queues, so the fleet does not
// shrink while long-running jobs are still executing. That narrows, but does
// not close, the race between a scale-in decision and task termination —
// ECS task scale-in protection (set from inside the task) is the real fix.
// Step-adjustment intervals are relative to the alarm thresholds, per the
// CloudWatch step-scaling contract.
//
// CloudWatch allows at most 10 metrics per alarm: queues + inflight queues
// + the task-count metric must stay within that.

locals {
  autoscaling_enabled = module.this.enabled && var.autoscaling_enabled && local.queue_in_use

  autoscaling_queue_weights = { for k in keys(var.queue_names) : k => lookup(var.queue_weights, k, var.queue_weight_default) }
  autoscaling_queue_procs   = { for k in keys(var.queue_names) : k => lookup(var.queue_processes, k, var.process_capacity_per_worker) }

  # Metric-math ids must match [a-z][a-zA-Z0-9_]*; queue names may not, so
  # derive ids from the sorted key position instead.
  autoscaling_queue_index = { for i, k in sort(keys(var.queue_names)) : k => i }

  autoscaling_inflight_index = { for k, i in local.autoscaling_queue_index : k => i if contains(var.scale_in_inflight_queues, k) }

  # Per-queue load expressions: (backlog * weight) / (tasks * pool slots).
  # The scale-down variant adds the in-flight metric where configured.
  autoscaling_load_exprs = {
    for k, i in local.autoscaling_queue_index :
    i => "(v${i} * ${local.autoscaling_queue_weights[k]}) / (tasks * ${local.autoscaling_queue_procs[k]})"
  }
  autoscaling_load_exprs_with_inflight = {
    for k, i in local.autoscaling_queue_index :
    i => "((v${i}${contains(var.scale_in_inflight_queues, k) ? " + n${i}" : ""}) * ${local.autoscaling_queue_weights[k]}) / (tasks * ${local.autoscaling_queue_procs[k]})"
  }

  autoscaling_max_expr = "MAX([${join(", ", [for i in values(local.autoscaling_queue_index) : "l${i}"])}])"
}

module "ecs_cloudwatch_autoscaling" {
  source  = "cloudposse/ecs-cloudwatch-autoscaling/aws"
  version = "1.0.0"

  enabled = local.autoscaling_enabled

  service_name                = module.ecs_task.service_name
  cluster_name                = var.ecs_cluster_name
  min_capacity                = var.autoscaling_min_capacity
  max_capacity                = var.autoscaling_max_capacity
  scale_up_step_adjustments   = var.autoscaling_scale_up_step_adjustments
  scale_up_cooldown           = var.autoscaling_scale_up_cooldown
  scale_down_step_adjustments = var.autoscaling_scale_down_step_adjustments
  scale_down_cooldown         = var.autoscaling_scale_down_cooldown

  context = module.this.context
}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  count = local.autoscaling_enabled ? 1 : 0

  alarm_name          = "${module.this.id}-scale-up"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.autoscaling_scale_up_threshold
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  alarm_description   = "Scale up ${module.ecs_task.service_name} when any queue's backlog per process slot exceeds threshold"
  treat_missing_data  = "notBreaching"

  dynamic "metric_query" {
    for_each = local.autoscaling_queue_index
    content {
      id = "v${metric_query.value}"
      metric {
        namespace   = "AWS/SQS"
        metric_name = "ApproximateNumberOfMessagesVisible"
        dimensions  = { QueueName = var.queue_names[metric_query.key] }
        period      = 60
        stat        = "Average"
      }
    }
  }

  metric_query {
    id = "tasks"
    metric {
      namespace   = "ECS/ContainerInsights"
      metric_name = "RunningTaskCount"
      dimensions = {
        ClusterName = var.ecs_cluster_name
        ServiceName = module.ecs_task.service_name
      }
      period = 60
      stat   = "Average"
    }
  }

  dynamic "metric_query" {
    for_each = local.autoscaling_load_exprs
    content {
      id         = "l${metric_query.key}"
      expression = metric_query.value
      label      = "Load per slot q${metric_query.key}"
    }
  }

  metric_query {
    id          = "workload_per_slot"
    expression  = local.autoscaling_max_expr
    label       = "Worst Queue Load Per Slot"
    return_data = true
  }

  alarm_actions = [module.ecs_cloudwatch_autoscaling.scale_up_policy_arn]

  tags = module.this.tags

  lifecycle {
    precondition {
      condition     = alltrue([for k in keys(var.queue_weights) : contains(keys(var.queue_names), k)])
      error_message = "Every queue_weights key must exist in queue_names."
    }
    precondition {
      condition     = alltrue([for k in keys(var.queue_processes) : contains(keys(var.queue_names), k)])
      error_message = "Every queue_processes key must exist in queue_names."
    }
    precondition {
      condition     = alltrue([for k in var.scale_in_inflight_queues : contains(keys(var.queue_names), k)])
      error_message = "Every scale_in_inflight_queues entry must exist in queue_names."
    }
    precondition {
      condition     = length(var.queue_names) + 1 <= 10
      error_message = "CloudWatch alarms allow at most 10 metrics: too many queues."
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  count = local.autoscaling_enabled ? 1 : 0

  alarm_name          = "${module.this.id}-scale-down"
  comparison_operator = "LessThanThreshold"
  threshold           = var.autoscaling_scale_down_threshold
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  # notBreaching: an idle-but-running service reports workload 0 and still
  # scales down; missing data (metric gaps, zero tasks) must not force scale-in.
  alarm_description  = "Scale down ${module.ecs_task.service_name} when every queue's backlog (including in-flight work on slow queues) is below threshold"
  treat_missing_data = "notBreaching"

  dynamic "metric_query" {
    for_each = local.autoscaling_queue_index
    content {
      id = "v${metric_query.value}"
      metric {
        namespace   = "AWS/SQS"
        metric_name = "ApproximateNumberOfMessagesVisible"
        dimensions  = { QueueName = var.queue_names[metric_query.key] }
        period      = 60
        stat        = "Average"
      }
    }
  }

  # In-flight messages on the slow queues: while a long job is executing its
  # message is not-visible, which holds this signal up and defers scale-in.
  dynamic "metric_query" {
    for_each = local.autoscaling_inflight_index
    content {
      id = "n${metric_query.value}"
      metric {
        namespace   = "AWS/SQS"
        metric_name = "ApproximateNumberOfMessagesNotVisible"
        dimensions  = { QueueName = var.queue_names[metric_query.key] }
        period      = 60
        stat        = "Average"
      }
    }
  }

  metric_query {
    id = "tasks"
    metric {
      namespace   = "ECS/ContainerInsights"
      metric_name = "RunningTaskCount"
      dimensions = {
        ClusterName = var.ecs_cluster_name
        ServiceName = module.ecs_task.service_name
      }
      period = 60
      stat   = "Average"
    }
  }

  dynamic "metric_query" {
    for_each = local.autoscaling_load_exprs_with_inflight
    content {
      id         = "l${metric_query.key}"
      expression = metric_query.value
      label      = "Load per slot q${metric_query.key}"
    }
  }

  metric_query {
    id          = "workload_per_slot"
    expression  = local.autoscaling_max_expr
    label       = "Worst Queue Load Per Slot"
    return_data = true
  }

  alarm_actions = [module.ecs_cloudwatch_autoscaling.scale_down_policy_arn]

  tags = module.this.tags

  lifecycle {
    precondition {
      condition     = length(var.queue_names) + length(var.scale_in_inflight_queues) + 1 <= 10
      error_message = "CloudWatch alarms allow at most 10 metrics: reduce queues or scale_in_inflight_queues."
    }
  }
}

//////////
// ECS Task Role Policies
//////////

// Allow ECS task to access SSM parameters
resource "aws_iam_role_policy_attachment" "ecs_task" {
  count      = module.this.enabled ? 1 : 0
  role       = module.ecs_task.task_role_name
  policy_arn = join("", aws_iam_policy.ecs_task.*.arn)
}

module "ecs_task_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = ["task"]
  context    = module.this.context
}

resource "aws_iam_policy" "ecs_task" {
  count  = module.this.enabled ? 1 : 0
  name   = module.ecs_task_label.id
  policy = data.aws_iam_policy_document.ecs_task.json
}

data "aws_iam_policy_document" "ecs_task" {

  # Allow ECS task to access SSM parameter store items
  statement {
    sid = ""

    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters"
    ]

    resources = [
      join("/", compact(["arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter",
        module.this.namespace,
        module.this.environment,
        module.this.stage,
        var.ssm_param_store_app_key,
        "*"
      ]))

    ]

    effect = "Allow"
  }
}

// Security Groups

resource "aws_security_group_rule" "allowed_ingress" {
  for_each                 = toset(var.allowed_ingress_security_group_ids)
  type                     = "ingress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  source_security_group_id = each.key
  security_group_id        = module.ecs_task.service_security_group_id
}

resource "aws_security_group_rule" "allowed_egress" {
  for_each                 = toset(var.allowed_ingress_security_group_ids)
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = each.key
  security_group_id        = module.ecs_task.service_security_group_id
}


// Service Discovery

resource "aws_service_discovery_service" "service_discovery" {
  count = var.use_service_discovery ? 1 : 0

  name = module.this.name
  dns_config {
    namespace_id   = var.service_discovery_private_dns_namespace_id
    routing_policy = "MULTIVALUE"

    dns_records {
      ttl  = 10
      type = "A"
    }

  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

// CodePipeline using ECS Deploy
module "ecs_codepipeline" {
  source  = "cloudposse/ecs-codepipeline/aws"
  version = "0.34.2"

  enabled = local.codepipeline_enabled

  region = var.aws_region

  repo_owner = var.codepipeline_repo_owner
  repo_name  = var.codepipeline_repo_name
  branch     = var.codepipeline_branch

  build_image        = var.codepipeline_build_image
  build_timeout      = var.codepipeline_build_timeout
  build_compute_type = var.codepipeline_build_compute_type
  buildspec          = var.codepipeline_buildspec

  poll_source_changes     = false
  codestar_connection_arn = var.codestar_connection_arn
  github_oauth_token      = var.codepipeline_github_oauth_token
  github_webhook_events   = var.codepipeline_github_webhook_events
  webhook_enabled         = var.codepipeline_webhook_enabled

  codebuild_vpc_config = var.codebuild_vpc_config

  // True required to build docker containers
  privileged_mode = true

  image_repo_name = split("/", module.ecr.repository_url)[0]
  image_tag       = "latest"

  cache_type              = var.codebuild_cache_type
  local_cache_modes       = var.codebuild_local_cache_modes
  s3_bucket_force_destroy = true

  environment_variables = concat(
    var.codepipeline_environment_variables,
    var.codepipeline_add_queue_env_vars ?
    [for queue_var in local.queue_env_vars : merge(queue_var, { type = "PLAINTEXT" })] : [],
    [
      {
        name  = "NAMESPACE"
        value = module.this.namespace
        type  = "PLAINTEXT"
      },
      {
        name  = "ENVIRONMENT"
        value = module.this.environment
        type  = "PLAINTEXT"
      },
      {
        name  = "BACKGROUND_ECR_REPO_URL"
        value = var.container_image == null ? module.ecr.repository_url_map[module.this.id] : ""
        type  = "PLAINTEXT"
      },
      {
        name  = "BACKGROUND_CONTAINER_NAME"
        value = module.container_label.id
        type  = "PLAINTEXT"
      }
    ]
  )
  ecs_cluster_name = var.ecs_cluster_name
  service_name     = module.ecs_task.service_name
  context          = module.this.context
}

module "codepipeline_notifications" {
  source  = "kjagiello/codepipeline-slack-notifications/aws"
  version = "3.1.0"

  for_each = local.codepipeline_enabled ? var.codepipeline_slack_notifications : {}

  name       = each.key
  namespace  = module.this.namespace
  stage      = module.this.stage
  attributes = concat([module.this.name, module.this.environment], module.this.attributes)

  lambda_runtime = "python3.12"

  slack_url     = each.value.webhook_url
  slack_channel = each.value.channel
  pipeline_event_type_ids = tolist(distinct(concat(
    flatten([for g in each.value.event_groups : local.codepipeline_group_events_map[g]]),
    each.value.event_ids
  )))

  codepipelines = [
    module.ecs_codepipeline.codepipeline_resource
  ]
}

// Block public ACLs for Codepipeline bucket
resource "aws_s3_bucket_public_access_block" "codepipeline_bucket_block_public" {
  count = local.codepipeline_enabled ? 1 : 0

  bucket                  = join("-", [module.this.id, "codepipeline"])
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

// Allow pull permission to CodeBuild

resource "aws_iam_role_policy_attachment" "codebuild" {
  count      = local.codepipeline_enabled ? 1 : 0
  role       = module.ecs_codepipeline.codebuild_role_id
  policy_arn = join("", aws_iam_policy.codebuild.*.arn)
}

resource "aws_iam_role_policy_attachment" "codebuild_additional_policies" {
  for_each   = module.this.enabled && var.codepipeline_enabled ? toset(var.codebuild_policy_arns) : []
  role       = module.ecs_codepipeline.codebuild_role_id
  policy_arn = each.value
}

module "codebuild_label" {
  //source     = "github.com/cloudposse/terraform-null-label.git?ref=0.21.0"
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  enabled    = local.codepipeline_enabled
  attributes = compact(concat(module.this.attributes, ["ecr"]))
  context    = module.this.context
}

resource "aws_iam_policy" "codebuild" {
  count  = local.codepipeline_enabled ? 1 : 0
  name   = module.codebuild_label.id
  policy = join("", data.aws_iam_policy_document.codebuild.*.json)
}

data "aws_iam_policy_document" "codebuild" {
  count = local.codepipeline_enabled ? 1 : 0

  # Allow CodeBuild to pull ECR images
  statement {
    sid = ""

    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]

    resources = values(module.ecr.repository_arn_map)
    effect    = "Allow"
  }

  // Allow getting task definition details
  statement {
    sid = ""

    actions = [
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition"
    ]

    resources = ["*"]
    effect    = "Allow"
  }

  // Allow tagging resources
  statement {
    sid = "AllowTagging"

    actions = [
      "ecs:TagResource"
    ]

    resources = ["*"]
    effect    = "Allow"
  }

}
