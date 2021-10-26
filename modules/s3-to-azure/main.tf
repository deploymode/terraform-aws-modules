###
#
# Creates backup service for automating S3 backups to Azure Storage, including:
# - ECS Fargate cluster
# - ECS Fargate service
# - EventBridge scheduled event
# - CI/CD services for deploying service code
#
# Used in conjunction with azure-storage module, which needs to be run in DR account.
#
###

// Cluster

module "cluster" {
  source = "../ecs-cluster"

  vpc_id                             = var.vpc_id
  container_insights_enabled         = false
  create_service_discovery_namespace = false

  context = module.this.context
}

module "service" {
  source = "../ecs-background"

  aws_region     = var.aws_region
  aws_account_id = var.aws_account_id

  ssm_param_store_app_key = module.this.name

  vpc_id           = var.vpc_id
  subnet_ids       = var.subnet_ids
  assign_public_ip = false

  # TODO
  # ecs_task_policy_arns = var.s3_backup_access_policy_arn

  ecs_cluster_arn  = module.cluster.arn[0]
  ecs_cluster_name = module.cluster.name[0]

  ecs_platform_version = "1.4.0"

  ecs_capacity_provider_strategies = [
    {
      capacity_provider = "FARGATE",
      weight            = 1,
      base              = 1
    }
  ]

  ecs_ignore_changes_task_definition = true

  // For FARGATE, CPU/Memory limits must fall into these limits: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html
  ecs_task_cpu           = 512
  ecs_task_memory        = 1024
  ecs_task_desired_count = 0 # Task is run via event trigger

  container_image = "peterdavehello/azcopy"
  container_command = ["azcopy",
    "sync",
    "https://s3.amazonaws.com/${var.s3_bucket_names[0]}",
    "$$AZURE_STORAGE_CONTAINER_SAS_ENDPOINT",
    "--recursive",
    "--log-level=INFO"
  ]
  container_cpu                = 512
  container_memory_reservation = 1024
  container_memory             = 1024
  container_start_timeout      = 240
  container_stop_timeout       = 120

  log_driver = "awslogs"

  container_port_mappings = []

  container_environment = [
    {
      name  = "STAGE"
      value = module.this.stage
      type  = "PLAINTEXT"
    },
    # {
    #   name  = "BUCKET_NAMES"
    #   value = join(",", var.s3_bucket_names)
    #   type  = "PLAINTEXT"
    # }
  ]

  container_secrets = [
    {
      "name" : "AZURE_STORAGE_CONTAINER_SAS_ENDPOINT"
      "valueFrom" : "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/${module.this.namespace}/${module.this.stage}/${module.this.name}/AZURE_STORAGE_CONTAINER_SAS_ENDPOINT"
    }
  ]

  // CodePipeline
  # codepipeline_github_oauth_token    = var.codepipeline_github_oauth_token
  # codepipeline_github_webhooks_token = var.codepipeline_github_webhooks_token
  # # https://developer.github.com/webhooks/event-payloads/
  # codepipeline_skip_deploy_step       = false
  # codepipeline_github_webhook_enabled = true
  # codepipeline_github_webhook_events  = ["push"]
  # codepipeline_repo_owner             = "medinfoconsenting"
  # codepipeline_repo_name              = "azure-backup"
  # codepipeline_branch                 = var.git_branch
  # codepipeline_buildspec              = "buildspec.yml"
  # codepipeline_build_image            = "aws/codebuild/standard:4.0"
  # codepipeline_build_compute_type     = "BUILD_GENERAL1_SMALL"
  # codepipeline_build_timeout          = 10
  # codepipeline_cache_type             = "S3"
  # # The following are set by the module:
  # # STAGE, AWS_REGION, AWS_ACCOUNT_ID, IMAGE_REPO_NAME, IMAGE_TAG, GITHUB_TOKEN, SERVICE_SECURITY_GROUPS
  # codepipeline_environment_variables = [
  #   {
  #     name  = "APP_NAME"
  #     value = module.this.name
  #     type  = "PLAINTEXT"
  #   }
  # ]

  context = module.this.context
}

# Task scheduling

# Schedule deployments each week

module "backup_schedule_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  attributes = ["schedule"]

  context = module.this.context
}

resource "aws_cloudwatch_event_rule" "daily_backup" {
  count               = var.backup_schedule != null ? 1 : 0
  name                = module.this.id
  description         = "Scheduled S3 backup"
  is_enabled          = module.this.enabled
  schedule_expression = var.backup_schedule
}

data "aws_ecs_task_definition" "task_def" {
  task_definition = module.service.ecs_task_definition_family

  depends_on = [
    module.service
  ]
}

resource "aws_cloudwatch_event_target" "ecs_scheduled_task" {
  arn      = module.cluster.arn[0]
  rule     = join("", aws_cloudwatch_event_rule.daily_backup.*.name)
  role_arn = join("", aws_iam_role.run_task_role.*.arn)
  ecs_target {
    launch_type      = "FARGATE"
    platform_version = "1.4.0"
    network_configuration {
      subnets          = var.subnet_ids
      security_groups  = [module.service.ecs_service_security_group_id]
      assign_public_ip = false
    }
    task_count          = 1
    task_definition_arn = "arn:aws:ecs:${var.aws_region}:${var.aws_account_id}:task-definition/${data.aws_ecs_task_definition.atlas_backup.family}"
  }
}

data "aws_iam_policy_document" "ecs_events_assume" {
  count = module.this.enabled ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "run_task_role" {
  count              = module.this.enabled ? 1 : 0
  name               = module.backup_schedule_label.id
  path               = "/service-role/"
  description        = "IAM role with permissions to run ECS task"
  assume_role_policy = join("", data.aws_iam_policy_document.ecs_events_assume.*.json)
}

resource "aws_iam_policy" "run_task_policy" {
  count       = module.this.enabled ? 1 : 0
  name        = join("-", [module.backup_schedule_label.id, "policy"])
  description = "Allow running an ECS task"
  policy      = data.aws_iam_policy_document.run_task_policy_document.json
}

data "aws_iam_policy_document" "run_task_policy_document" {

  statement {
    sid = ""

    actions = [
      "iam:PassRole"
    ]

    resources = ["*"]

    effect = "Allow"
  }

  statement {
    sid = ""

    actions = [
      "ecs:RunTask"
    ]

    resources = [
      "arn:aws:ecs:${var.aws_region}:${var.aws_account_id}:task-definition/${data.aws_ecs_task_definition.atlas_backup.family}"
    ]

    effect = "Allow"
  }
}

resource "aws_iam_role_policy_attachment" "run_task_attach" {
  count      = module.this.enabled ? 1 : 0
  role       = join("", aws_iam_role.run_task_role.*.name)
  policy_arn = join("", aws_iam_policy.run_task_policy.*.arn)
}
