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

  // Auto-scaling

  process_capacity_per_worker = var.process_capacity_per_worker
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


// Auto-scaling based on SQS queue metrics

module "ecs_cloudwatch_autoscaling" {  
  source                = "cloudposse/ecs-cloudwatch-autoscaling/aws"
  version               = "1.0.0"

  enabled               = module.this.enabled && var.autoscaling_enabled

  service_name          = module.ecs_task.service_name
  cluster_name          = var.ecs_cluster_name
  min_capacity          = var.autoscaling_min_capacity
  max_capacity          = var.autoscaling_max_capacity
  scale_down_step_adjustments = var.autoscaling_scale_down_thresholds
  scale_down_cooldown   = var.autoscaling_scale_down_cooldown
  scale_up_step_adjustments = var.autoscaling_scale_up_thresholds
  scale_up_cooldown     = var.autoscaling_scale_up_cooldown

  context                = module.this.context
}

# CLOUDWATCH ALARMS for SQS
# Custom metrics for scaling based on weighted queue messages per process slot

# Helper function for metric query ids to avoid duplicates
locals {
  queue_ids = [for queue_name, _ in var.queue_weights : "q${queue_name}"]
}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  count = local.queue_in_use ? 1 : 0

  alarm_name          = "ecs-scale-up-alarm"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.scale_up_thresholds[0].lower_bound
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  period              = 60
  alarm_description   = "Scale up ECS when workload per process slot exceeds threshold"
  treat_missing_data  = "notBreaching"

  # Queue metrics with weights
  dynamic "metric_query" {
    for_each = var.queue_weights
    content {
      id = local.queue_ids[metric_query.key]
      metric {
        namespace   = "AWS/SQS"
        metric_name = "ApproximateNumberOfMessagesVisible"
        dimensions  = { QueueName = metric_query.key }
        period      = 60
        stat        = "Average"
      }
    }
  }

  # Running ECS tasks
  metric_query {
    id          = "tasks"
    metric {
      namespace   = "ECS/Service"
      metric_name = "RunningTaskCount"
      dimensions  = {
        ClusterName = var.ecs_cluster_name
        ServiceName = module.ecs_task.service_name
      }
      period = 60
      stat   = "Average"
    }
  }

  # Weighted sums for queues
  metric_query {
    id         = "weighted"
    expression = join(" + ", [for queue_name, weight in var.queue_weights : "(${local.queue_ids[queue_name]} * ${weight})"])
    label      = "Weighted Queue Messages"
  }

  # Workload per ECS process slot
  metric_query {
    id         = "workload_per_slot"
    expression = "weighted / (tasks * ${local.process_capacity_per_worker})"
    label      = "Workload Per Slot"
    return_data = true
  }

  alarm_actions = [aws_appautoscaling_policy.scale_out.arn]
  ok_actions    = []
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  count = local.queue_in_use ? 1 : 0

  alarm_name          = "ecs-scale-down-alarm"
  comparison_operator = "LessThanThreshold"
  threshold           = var.autoscaling_scale_down_thresholds[0].upper_bound
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  period              = 60
  alarm_description   = "Scale down ECS when workload per process slot drops below threshold"
  treat_missing_data  = "breaching"

  # Repeat same metric queries as scale-up alarm
  dynamic "metric_query" {
    for_each = var.queue_weights
    content {
      id = local.queue_ids[metric_query.key]
      metric {
        namespace   = "AWS/SQS"
        metric_name = "ApproximateNumberOfMessagesVisible"
        dimensions  = { QueueName = metric_query.key }
        period      = 60
        stat        = "Average"
      }
    }
  }

  metric_query {
    id          = "tasks"
    metric {
      namespace   = "ECS/Service"
      metric_name = "RunningTaskCount"
      dimensions  = {
        ClusterName = var.ecs_cluster_name
        ServiceName = module.ecs_task.service_name
      }
      period = 60
      stat   = "Average"
    }
  }

  metric_query {
    id         = "weighted"
    expression = join(" + ", [for queue_name, weight in var.queue_weights : "(${local.queue_ids[queue_name]} * ${weight})"])
    label      = "Weighted Queue Messages"
  }

  metric_query {
    id         = "workload_per_slot"
    expression = "weighted / (tasks * ${local.process_capacity_per_worker})"
    label      = "Workload Per Slot"
    return_data = true
  }

  alarm_actions = [aws_appautoscaling_policy.scale_in.arn]
  ok_actions    = []
}

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
