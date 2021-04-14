locals {
  image_names_map = {
    "nginx" = format("%s-%s", "nginx", module.this.stage)
    "php"   = format("%s-%s", "php-fpm", module.this.stage)
  }
  log_groups = {
    nginx = "/ecs/${module.container_label.id}/${local.image_names_map.nginx}"
    php   = "/ecs/${module.container_label.id}/${local.image_names_map.php}"
  }

  # db_env_vars = length(var.database_host) > 0 ? [
  #   {
  #     name  = "DB_HOST"
  #     value = var.database_host
  #   },
  #   {
  #     name  = "DB_DATABASE"
  #     value = var.database_name
  #   },
  #   {
  #     name  = "DB_PORT"
  #     value = var.database_port
  #   },
  #   {
  #     name  = "DB_USERNAME"
  #     value = var.database_username
  #   },
  #   {
  #     name  = "DB_PASSWORD"
  #     value = var.database_password
  #   }
  # ] : []

  queue_env_vars = var.provision_sqs ? [
    {
      name  = "SQS_QUEUE"
      value = module.queue.this_sqs_queue_name
    },
    {
      name  = "SQS_PREFIX"
      value = "https://sqs.${var.aws_region}.amazonaws.com/${var.aws_account_id}"
    },
  ] : []

  cache_env_vars = var.provision_cache ? [
    {
      name  = "REDIS_HOST"
      value = module.redis.endpoint
    }
  ] : []
}

// ECR Registry/Repo
module "ecr" {
  source       = "cloudposse/ecr/aws"
  version      = "0.32.2"
  use_fullname = true
  image_names = [
    local.image_names_map.nginx,
    local.image_names_map.php
  ]
  image_tag_mutability = "MUTABLE"
  context              = module.this.context
}


// Container Defs
module "container_label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.24.1"
  attributes = compact(concat(module.this.attributes, ["container"]))
  context    = module.this.context
}

module "container_nginx" {
  source                       = "git::https://github.com/cloudposse/terraform-aws-ecs-container-definition.git?ref=tags/0.56.0"
  container_name               = join("-", [module.container_label.id, "nginx"])
  container_image              = join(":", [module.ecr.repository_url_map[local.image_names_map.nginx], "latest"])
  container_memory             = var.container_memory_nginx
  container_memory_reservation = var.container_memory_reservation_nginx
  container_cpu                = var.container_cpu_nginx
  start_timeout                = var.container_start_timeout
  stop_timeout                 = var.container_stop_timeout
  # Task will stop if this container fails
  essential                = true
  readonly_root_filesystem = false
  environment              = var.container_environment_nginx
  secrets                  = var.container_secrets_nginx

  port_mappings = [
    {
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }
  ]

  # command         = [""]

  log_configuration = {
    "logDriver" : var.log_driver,
    "secretOptions" : null,
    "options" : {
      "awslogs-group" : local.log_groups.nginx // "/ecs/${module.container_label.id}/${local.image_names_map.nginx}",
      "awslogs-region" : var.aws_region,
      "awslogs-stream-prefix" : "ecs",
      "awslogs-create-group" : "true"
    }
  }
}

module "container_php-fpm" {
  source                       = "git::https://github.com/cloudposse/terraform-aws-ecs-container-definition.git?ref=tags/0.56.0"
  container_name               = join("-", [module.container_label.id, "php-fpm"])
  container_image              = join(":", [module.ecr.repository_url_map[local.image_names_map.php], "latest"])
  container_memory             = var.container_memory_php
  container_memory_reservation = var.container_memory_reservation_php
  container_cpu                = var.container_cpu_php
  start_timeout                = var.container_start_timeout
  stop_timeout                 = var.container_stop_timeout
  # Task will stop if this container fails
  essential                = true
  readonly_root_filesystem = false
  environment              = concat(var.container_environment_php, local.cache_env_vars, local.queue_env_vars)
  secrets                  = var.container_secrets_php
  # local.db_env_vars

  port_mappings = [
    {
      containerPort = 9000
      hostPort      = 9000
      protocol      = "tcp"
    }
  ]

  # command         = [""]

  log_configuration = {
    "logDriver" : var.log_driver,
    "secretOptions" : null,
    "options" : {
      "awslogs-group" : local.log_groups.php // "/ecs/${module.container_label.id}/${local.image_names_map.php}",
      "awslogs-region" : var.aws_region,
      "awslogs-stream-prefix" : "ecs",
      "awslogs-create-group" : "true"
    }
  }
}

module "alb" {
  source             = "git::https://github.com/cloudposse/terraform-aws-alb.git?ref=tags/0.21.0"
  context            = module.this.context
  attributes         = compact(concat(module.this.attributes, ["alb"]))
  vpc_id             = var.vpc_id
  security_group_ids = var.alb_security_group_ids
  subnet_ids         = var.public_subnet_ids
  target_group_name  = module.this.id
  # target_group_port                       = var.target_group_port
  internal                                = false
  http_port                               = var.http_port
  https_port                              = var.https_port
  http_enabled                            = var.http_enabled
  https_enabled                           = var.https_enabled
  http_redirect                           = var.http_to_https_redirect
  certificate_arn                         = var.certificate_arn
  access_logs_enabled                     = false
  alb_access_logs_s3_bucket_force_destroy = true
  cross_zone_load_balancing_enabled       = true
  http2_enabled                           = true
  deletion_protection_enabled             = false
  tags                                    = var.tags
}

module "ecs_task" {
  source                 = "cloudposse/ecs-alb-service-task/aws"
  version                = "0.55.0"
  context                = module.this.context
  attributes             = compact(concat(module.this.attributes, ["service"]))
  alb_security_group     = module.alb.security_group_id # var.alb_security_group_id
  use_alb_security_group = var.use_alb_security_group
  security_group_ids     = var.ecs_security_group_ids
  ecs_load_balancers = [
    {
      container_name   = join("-", [module.container_label.id, "nginx"])
      container_port   = 80
      elb_name         = null
      target_group_arn = module.alb.default_target_group_arn # var.alb_target_group_arn
    }
  ]
  container_definition_json = jsonencode([
    module.container_nginx.json_map_object,
    module.container_php-fpm.json_map_object
  ])
  #  "[${module.container_nginx.json_map_encoded},${module.container_php-fpm.json_map_encoded}]"
  ecs_cluster_arn                = var.ecs_cluster_arn
  capacity_provider_strategies   = var.ecs_capacity_provider_strategies
  launch_type                    = var.ecs_launch_type
  platform_version               = var.ecs_platform_version
  vpc_id                         = var.vpc_id
  subnet_ids                     = var.private_subnet_ids
  tags                           = var.tags
  ignore_changes_task_definition = true

  network_mode     = var.ecs_network_mode
  assign_public_ip = var.assign_public_ip
  propagate_tags   = "TASK_DEFINITION"
  # deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  # deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_controller_type = "ECS"
  desired_count              = var.ecs_task_desired_count
  task_memory                = var.ecs_task_memory
  task_cpu                   = var.ecs_task_cpu
}

resource "aws_route53_record" "default" {
  count   = var.hosted_zone_id != "" ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = join(".", [module.this.name, module.this.environment, var.domain_name])
  type    = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }
}

// CodePipeline

module "ecs_codepipeline" {
  source = "git::https://github.com/joe-niland/terraform-aws-ecs-codepipeline.git?ref=disable-codestar-condition"
  # source                  = "cloudposse/ecs-codepipeline/aws"
  # version                 = "0.24.0"
  context                 = module.this.context
  region                  = var.aws_region
  codestar_connection_arn = var.codestar_connection_arn
  repo_owner              = var.codepipeline_repo_owner
  repo_name               = var.codepipeline_repo_name
  branch                  = var.codepipeline_branch
  build_image             = var.codepipeline_build_image
  build_timeout           = var.codepipeline_build_timeout
  build_compute_type      = "BUILD_GENERAL1_SMALL"
  poll_source_changes     = false
  // True required to build docker containers
  privileged_mode         = true
  image_repo_name         = split("/", module.ecr.repository_url)[0]
  image_tag               = "latest" // var.image_tag
  webhook_enabled         = false
  s3_bucket_force_destroy = true
  environment_variables   = var.codepipeline_environment_variables
  ecs_cluster_name        = var.ecs_cluster_name
  service_name            = module.ecs_task.service_name
  cache_type              = var.codebuild_cache_type
  local_cache_modes       = var.codebuild_local_cache_modes
  # github_anonymous        = true
  github_oauth_token    = ""
  github_webhooks_token = ""
}

// Allow pull permission to CodeBuild

//codebuild_role_arn

resource "aws_iam_role_policy_attachment" "codebuild" {
  count      = module.this.enabled ? 1 : 0
  role       = module.ecs_codepipeline.codebuild_role_id
  policy_arn = join("", aws_iam_policy.codebuild.*.arn)
}

module "codebuild_label" {
  source     = "github.com/cloudposse/terraform-null-label.git?ref=0.24.1"
  attributes = compact(concat(module.this.attributes, ["ecr"]))
  context    = module.this.context
}

resource "aws_iam_policy" "codebuild" {
  count  = module.this.enabled ? 1 : 0
  name   = module.codebuild_label.id
  policy = data.aws_iam_policy_document.codebuild.json
}

data "aws_iam_policy_document" "codebuild" {

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

  # Allow CodeBuild to create report groups
  statement {
    sid = ""

    actions = [
      "codebuild:CreateReport*",
      "codebuild:UpdateReport*",
      "codebuild:BatchPutTestCases"
    ]

    resources = [
      join(":", [
        "arn:aws:codebuild",
        var.aws_region,
        var.aws_account_id,
        join("/", [
          "report-group",
          join("-", [module.this.id, "*"])
        ])
      ])
    ]
    effect = "Allow"
  }
}

// VPC Peering with Database VPC

module "vpc_peering" {
  source                                    = "cloudposse/vpc-peering/aws"
  version                                   = "0.9.0"
  enabled                                   = (module.this.enabled && length(var.peered_vpc_id) > 0)
  auto_accept                               = true
  requestor_allow_remote_vpc_dns_resolution = true
  acceptor_allow_remote_vpc_dns_resolution  = true
  requestor_vpc_id                          = var.vpc_id
  acceptor_vpc_id                           = var.peered_vpc_id
  create_timeout                            = "5m"
  update_timeout                            = "5m"
  delete_timeout                            = "10m"
  context                                   = module.this.context
}

module "redis" {
  source                       = "cloudposse/elasticache-redis/aws"
  version                      = "0.37.0"
  enabled                      = (module.this.enabled && var.provision_cache)
  attributes                   = compact(concat(module.this.attributes, ["cache"]))
  availability_zones           = var.redis_availability_zones
  zone_id                      = var.hosted_zone_id
  vpc_id                       = var.vpc_id
  use_existing_security_groups = true
  allowed_security_groups = compact(concat([
    # var.redis_allowed_security_group_ids,
    module.ecs_task.service_security_group_id
  ]))
  subnets                    = var.private_subnet_ids
  cluster_size               = var.redis_cluster_size
  instance_type              = var.redis_instance_type
  apply_immediately          = true
  automatic_failover_enabled = false
  engine_version             = var.redis_engine_version
  family                     = var.redis_family
  at_rest_encryption_enabled = false
  transit_encryption_enabled = true
  auth_token                 = var.redis_password

  context = module.this.context
}

// SQS
data "aws_iam_policy_document" "sqs" {
  count = (module.this.enabled && var.provision_sqs) ? 1 : 0

  # Allow ECS task to access SSM parameter store items
  statement {
    sid = ""

    principals {
      type        = "AWS"
      identifiers = [module.ecs_task.task_exec_role_arn]
    }

    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:GetQueueUrl"
    ]

    resources = [
      module.queue.this_sqs_queue_arn
    ]

    effect = "Allow"
  }
}

resource "aws_sqs_queue_policy" "sqs" {
  count     = (module.this.enabled && var.provision_sqs) ? 1 : 0
  queue_url = module.queue.this_sqs_queue_id
  policy    = join("", data.aws_iam_policy_document.sqs.*.json)
}

module "queue" {
  source  = "terraform-aws-modules/sqs/aws"
  version = ">= 2.0"
  create  = (module.this.enabled && var.provision_sqs)
  name    = module.this.name
  tags    = module.this.tags
}
