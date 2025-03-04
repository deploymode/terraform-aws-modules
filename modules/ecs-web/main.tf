locals {

  default_queue_name = "app"
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
  monitoring_container_enabled = module.this.enabled && var.monitoring_image_name != null
}

data "aws_caller_identity" "current" {}

module "nginx_image_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = ["nginx"]
  context    = module.this.context
}

module "php-fpm_image_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = ["php-fpm"]
  context    = module.this.context
}

module "monitoring_image_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = ["monitoring"]
  context    = module.this.context
}

locals {
  # ECS app
  app_fqdn = join(".", [var.app_dns_name, var.domain_name])
  # Frontend (S3) app
  frontend_fqdn = join(".", [var.frontend_dns_name, var.domain_name])

  image_names_map = {
    "nginx"      = module.nginx_image_label.id
    "php"        = module.php-fpm_image_label.id
    "monitoring" = module.monitoring_image_label.id
  }

  log_groups = merge({
    nginx = "/ecs/${module.container_label.id}/${local.image_names_map.nginx}"
    php   = "/ecs/${module.container_label.id}/${local.image_names_map.php}"
    },
    local.monitoring_container_enabled ? {
      monitoring = "/ecs/${module.container_label.id}/${local.image_names_map.monitoring}"
    } : {}
  )

  build_log_groups = var.codepipeline_enabled ? {
    codebuild = "/aws/codebuild/${module.this.id}-build"
  } : {}

  queue_env_vars = length(var.queue_names) > 0 ? concat([
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
  source       = "cloudposse/ecr/aws"
  version      = "0.42.1"
  use_fullname = true
  image_names = [
    local.image_names_map.nginx,
    local.image_names_map.php
  ]
  image_tag_mutability    = "MUTABLE"
  enable_lifecycle_policy = true
  max_image_count         = var.ecr_max_image_count
  force_delete            = var.ecr_force_delete

  context = module.this.context
}

// Container Defs
module "container_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = ["container"]
  context    = module.this.context
}

module "nginx_container_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = ["nginx"]
  context    = module.container_label.context
}

module "container_nginx" {
  source                       = "cloudposse/ecs-container-definition/aws"
  version                      = "0.58.1"
  container_name               = module.nginx_container_label.id #join("-", [module.container_label.id, "nginx"])
  container_image              = join(":", [module.ecr.repository_url_map[local.image_names_map.nginx], "latest"])
  container_memory             = var.container_memory_nginx
  container_memory_reservation = var.container_memory_reservation_nginx
  container_cpu                = var.container_cpu_nginx
  start_timeout                = var.container_start_timeout
  stop_timeout                 = var.container_stop_timeout
  # Task will stop if this container fails
  essential = true

  healthcheck = var.container_healthcheck_nginx

  readonly_root_filesystem = false

  environment = var.container_environment_nginx
  secrets     = var.container_ssm_secrets_nginx

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

module "php-fpm_container_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = ["php-fpm"]
  context    = module.container_label.context
}

module "container_php-fpm" {
  source                       = "cloudposse/ecs-container-definition/aws"
  version                      = "0.58.1"
  container_name               = module.php-fpm_container_label.id # join("-", [module.container_label.id, "php-fpm"])
  container_image              = join(":", [module.ecr.repository_url_map[local.image_names_map.php], "latest"])
  container_memory             = var.container_memory_php
  container_memory_reservation = var.container_memory_reservation_php
  container_cpu                = var.container_cpu_php
  start_timeout                = var.container_start_timeout
  stop_timeout                 = var.container_stop_timeout

  # Task will stop if this container fails
  essential = true

  healthcheck = var.container_healthcheck_php

  container_depends_on = local.monitoring_container_enabled && var.monitoring_container_dependency ? [{
    containerName = module.monitoring_container_label.id
    condition     = "HEALTHY"
  }] : null

  readonly_root_filesystem = false

  environment = concat([
    {
      name  = "STAGE"
      value = module.this.stage
    },
    {
      name  = "ENVIRONMENT"
      value = module.this.environment
    },
    ],
    var.container_environment_php,
    local.queue_env_vars
  )
  secrets = var.container_ssm_secrets_php

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

module "monitoring_container_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = ["monitoring"]
  enabled    = local.monitoring_container_enabled
  context    = module.container_label.context
}

module "container_monitoring" {
  source                       = "cloudposse/ecs-container-definition/aws"
  version                      = "0.58.1"
  count                        = local.monitoring_container_enabled ? 1 : 0
  container_name               = module.monitoring_container_label.id
  container_image              = var.monitoring_image_name
  container_memory             = var.monitoring_container_memory
  container_memory_reservation = var.monitoring_container_memory_reservation
  container_cpu                = var.monitoring_container_cpu
  start_timeout                = var.container_start_timeout
  stop_timeout                 = var.container_stop_timeout
  # Task will stop if this container fails
  essential = false
  healthcheck = {
    command = [
      "netstat -an | grep ${var.monitoring_container_port} > /dev/null"
    ]
    retries     = 1
    timeout     = 5
    interval    = 5
    startPeriod = 30
  }
  readonly_root_filesystem = false
  environment = [
    {
      name  = "STAGE"
      value = module.this.stage
    },
    {
      name  = "ENVIRONMENT"
      value = module.this.environment
    },
  ]
  # secrets = var.container_ssm_secrets_php

  port_mappings = [
    {
      containerPort = var.monitoring_container_port
      hostPort      = var.monitoring_container_port
      protocol      = "tcp"
    }
  ]

  # command         = [""]

  log_configuration = {
    "logDriver" : var.log_driver,
    "secretOptions" : null,
    "options" : {
      "awslogs-group" : local.log_groups.monitoring
      "awslogs-region" : var.aws_region,
      "awslogs-stream-prefix" : "ecs",
      "awslogs-create-group" : "true"
    }
  }
}

module "alb_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = ["alb"]
  context    = module.this.context
}

module "alb" {
  source             = "cloudposse/alb/aws"
  version            = "1.10.0"
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
  health_check_path                       = var.alb_healthcheck_path
  health_check_timeout                    = var.alb_healthcheck_timeout
  health_check_interval                   = var.alb_healthcheck_interval
  certificate_arn                         = var.certificate_arn
  access_logs_enabled                     = var.alb_access_logs_enabled
  alb_access_logs_s3_bucket_force_destroy = var.alb_access_logs_s3_bucket_force_destroy
  # alb_access_logs_s3_bucket_force_destroy_enabled = var.alb_access_logs_s3_bucket_force_destroy ? "true" : "false"
  cross_zone_load_balancing_enabled = true
  http2_enabled                     = true
  deletion_protection_enabled       = false
  https_ssl_policy                  = var.alb_https_ssl_policy
  context                           = module.alb_label.context
}

resource "aws_route53_record" "default" {
  for_each = toset(var.hosted_zone_id != "" ? concat(var.create_alb_dns_record ? [local.app_fqdn] : [], var.alb_dns_aliases) : [])

  zone_id = var.hosted_zone_id
  name    = each.key
  type    = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }
}

module "ecs_task" {
  source  = "cloudposse/ecs-alb-service-task/aws"
  version = "0.76.1"

  # Network
  vpc_id             = var.vpc_id
  network_mode       = var.ecs_network_mode
  assign_public_ip   = var.assign_public_ip
  subnet_ids         = var.private_subnet_ids
  security_group_ids = var.ecs_security_group_ids

  # ALB
  alb_security_group     = module.alb.security_group_id
  use_alb_security_group = var.use_alb_security_group
  ecs_load_balancers = [
    {
      container_name   = join("-", [module.container_label.id, "nginx"])
      container_port   = 80
      elb_name         = null
      target_group_arn = module.alb.default_target_group_arn # var.alb_target_group_arn
    }
  ]
  container_definition_json = jsonencode(
    concat([
      module.container_nginx.json_map_object,
      module.container_php-fpm.json_map_object
      ],
      local.monitoring_container_enabled ? [module.container_monitoring[0].json_map_object] : []
    )
  )
  track_latest                 = var.ecs_task_def_track_latest
  ecs_cluster_arn              = var.ecs_cluster_arn
  capacity_provider_strategies = var.ecs_capacity_provider_strategies
  launch_type                  = var.ecs_launch_type
  platform_version             = var.ecs_platform_version
  task_policy_arns_map = merge(
    var.ecs_task_policy_arns,
    var.allow_email_sending ? { email_smtp = join("", aws_iam_policy.email_policy.*.arn) } : {},
    { for k, v in aws_iam_policy.app_bucket_iam_policy : k => v.arn }
  )
  exec_enabled                   = var.ecs_enable_exec
  ignore_changes_task_definition = var.ecs_ignore_changes_task_definition
  # task_definition_family_only    = var.task_definition_family_only

  propagate_tags = "TASK_DEFINITION"

  # Deployment
  health_check_grace_period_seconds  = var.ecs_health_check_grace_period_seconds
  deployment_minimum_healthy_percent = var.ecs_deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.ecs_deployment_maximum_percent
  deployment_controller_type         = "ECS"
  circuit_breaker_deployment_enabled = var.ecs_circuit_breaker_deployment_enabled
  circuit_breaker_rollback_enabled   = var.ecs_circuit_breaker_rollback_enabled
  force_new_deployment               = var.service_force_new_deployment
  redeploy_on_apply                  = var.service_redeploy_on_apply

  desired_count = var.ecs_task_desired_count
  task_memory   = var.ecs_task_memory
  task_cpu      = var.ecs_task_cpu

  context = module.this.context
}

module "email_policy_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = ["email"]
  context    = module.this.context
}

resource "aws_iam_policy" "email_policy" {
  count  = module.this.enabled && var.allow_email_sending ? 1 : 0
  name   = module.email_policy_label.id
  path   = "/"
  policy = join("", data.aws_iam_policy_document.send_email_policy.*.json)
}

data "aws_iam_policy_document" "send_email_policy" {
  count = module.this.enabled && var.allow_email_sending ? 1 : 0
  statement {
    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail"
    ]

    resources = [
      "*"
    ]
  }
}

###
## CDN
#
module "label_cdn" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = ["cdn"]
  context    = module.this.context
}

module "label_cdn_response" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = ["response"]
  context    = module.label_cdn.context
}

resource "aws_cloudfront_response_headers_policy" "default" {
  name = module.label_cdn_response.id

  security_headers_config {
    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "SAMEORIGIN"
      override     = true
    }

    referrer_policy {
      referrer_policy = var.cdn_headers_response_security_referrer
      override        = true
    }

    dynamic "strict_transport_security" {
      for_each = var.cdn_headers_response_security_sts != null ? [var.cdn_headers_response_security_sts] : []

      content {
        access_control_max_age_sec = strict_transport_security.value.access_control_max_age_sec
        include_subdomains         = strict_transport_security.value.include_subdomains
        preload                    = strict_transport_security.value.preload
        override                   = true
      }
    }
  }

  remove_headers_config {
    dynamic "items" {
      for_each = var.cdn_headers_response_remove # != null ? [var.cdn_headers_response_remove] : []
      content {
        header = items.value
      }
    }
  }

  dynamic "custom_headers_config" {
    for_each = var.cdn_headers_response_custom != null ? [var.cdn_headers_response_custom] : []

    content {
      dynamic "items" {
        for_each = custom_headers_config.value
        content {
          header   = items.key
          override = items.value.override
          value    = items.value.header_value
        }
      }
    }
  }


}

module "cdn" {
  source  = "cloudposse/cloudfront-cdn/aws"
  version = "1.0.0"
  enabled = module.this.enabled && var.use_cdn

  aliases                         = concat([local.app_fqdn], var.app_dns_aliases)
  http_version                    = var.cdn_http_version
  origin_domain_name              = module.alb.alb_dns_name
  origin_protocol_policy          = "match-viewer"
  origin_keepalive_timeout        = var.cdn_origin_keepalive_timeout
  origin_read_timeout             = var.cdn_origin_read_timeout
  origin_ssl_protocols            = var.cdn_origin_ssl_protocols
  viewer_protocol_policy          = "redirect-to-https"
  viewer_minimum_protocol_version = var.cdn_viewer_min_protocol_version
  response_headers_policy_id      = aws_cloudfront_response_headers_policy.default.id
  parent_zone_name                = var.domain_name
  dns_aliases_enabled             = var.create_cdn_dns_records
  default_root_object             = ""
  acm_certificate_arn             = var.cdn_certificate_arn
  forward_cookies                 = "all"
  forward_headers                 = ["*"]
  forward_query_string            = true
  default_ttl                     = var.cdn_default_ttl
  min_ttl                         = var.cdn_min_ttl
  max_ttl                         = var.cdn_max_ttl
  compress                        = true
  cached_methods                  = ["GET", "HEAD"]
  allowed_methods                 = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
  price_class                     = "PriceClass_All"
  logging_enabled                 = var.cdn_logging_enabled
  log_bucket_fqdn                 = var.cdn_log_bucket_fqdn
  log_prefix                      = var.cdn_log_prefix
  log_force_destroy               = var.cdn_log_force_destroy
  log_expiration_days             = var.cdn_log_expiration_days
  log_include_cookies             = var.cdn_log_include_cookies
  log_standard_transition_days    = var.cdn_log_standard_transition_days
  log_glacier_transition_days     = var.cdn_log_glacier_transition_days

  context = module.label_cdn.context
}

// CodePipeline

resource "aws_codestarconnections_connection" "default" {
  count         = module.this.enabled && var.codepipeline_enabled && var.codestar_connection_arn == null ? 1 : 0
  name          = module.this.id
  provider_type = var.codestar_provider_type
}

module "ecs_codepipeline" {
  source  = "cloudposse/ecs-codepipeline/aws"
  version = "0.34.2"

  enabled                         = var.codepipeline_enabled
  region                          = var.aws_region
  codestar_connection_arn         = coalesce(var.codestar_connection_arn, join("", aws_codestarconnections_connection.default.*.arn))
  codestar_output_artifact_format = var.codestar_output_artifact_format
  repo_owner                      = var.codepipeline_repo_owner
  repo_name                       = var.codepipeline_repo_name
  branch                          = var.codepipeline_branch
  build_image                     = var.codepipeline_build_image
  build_timeout                   = var.codepipeline_build_timeout
  build_compute_type              = "BUILD_GENERAL1_SMALL"
  poll_source_changes             = false
  // True required to build docker containers
  privileged_mode         = true
  image_repo_name         = split("/", module.ecr.repository_url)[0]
  image_tag               = "latest" // var.image_tag
  webhook_enabled         = var.codepipeline_webhook_enabled
  s3_bucket_force_destroy = true
  environment_variables = concat(
    var.codepipeline_environment_variables,
    var.codepipeline_add_queue_env_vars ?
    [for var in local.queue_env_vars : merge(var, { type = "PLAINTEXT" })] : [],
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
        name  = "NGINX_ECR_REPO_URL"
        value = module.ecr.repository_url_map[local.image_names_map.nginx]
        type  = "PLAINTEXT"
      },
      {
        name  = "PHP_ECR_REPO_URL"
        value = module.ecr.repository_url_map[local.image_names_map.php]
        type  = "PLAINTEXT"
      },
      {
        name  = "NGINX_CONTAINER_NAME"
        value = module.nginx_container_label.id
        type  = "PLAINTEXT"
      },
      {
        name  = "PHP_CONTAINER_NAME"
        value = module.php-fpm_container_label.id
        type  = "PLAINTEXT"
      }
    ]
  )
  ecs_cluster_name  = var.ecs_cluster_name
  service_name      = module.ecs_task.service_name
  cache_type        = var.codebuild_cache_type
  local_cache_modes = var.codebuild_local_cache_modes
  # github_anonymous        = true
  github_oauth_token   = ""
  codebuild_vpc_config = var.codebuild_vpc_config

  context = module.this.context
}

module "codepipeline_notifications" {
  source  = "kjagiello/codepipeline-slack-notifications/aws"
  version = "3.1.0"

  for_each = module.this.enabled && var.codepipeline_enabled ? var.codepipeline_slack_notifications : {}

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

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObjectAcl",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObjectAcl"
    ]

    resources = [
      "arn:aws:s3:::bucket_name/*",
      "arn:aws:s3:::bucket_name/"
    ]
  }
}

// Allow pull permission to CodeBuild

resource "aws_iam_role_policy_attachment" "codebuild" {
  count      = module.this.enabled && var.codepipeline_enabled ? 1 : 0
  role       = module.ecs_codepipeline.codebuild_role_id
  policy_arn = join("", aws_iam_policy.codebuild.*.arn)
}

resource "aws_iam_role_policy_attachment" "codebuild_additional_policies" {
  for_each   = module.this.enabled && var.codepipeline_enabled ? toset(var.codebuild_policy_arns) : []
  role       = module.ecs_codepipeline.codebuild_role_id
  policy_arn = each.value
}

# Allow Codebuild to read/write from S3 buckets
# TODO: deprecate this
resource "aws_iam_role_policy_attachment" "codebuild_app_bucket" {
  for_each   = toset(module.this.enabled && var.codepipeline_enabled ? var.external_app_buckets : [])
  role       = module.ecs_codepipeline.codebuild_role_id
  policy_arn = aws_iam_policy.app_bucket_iam_policy[each.key].arn
}

module "codebuild_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = ["ecr"]
  context    = module.this.context
}

resource "aws_iam_policy" "codebuild" {
  count  = module.this.enabled && var.codepipeline_enabled ? 1 : 0
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

// Bucket access
// TODO: deprecate this
module "app_bucket_iam_policy" {
  source  = "cloudposse/iam-policy/aws"
  version = "2.0.1"

  for_each = toset(var.external_app_buckets)

  iam_policy_statements = [
    {
      sid        = "ListBucket"
      effect     = "Allow"
      actions    = ["s3:ListBucket"]
      resources  = ["arn:aws:s3:::${each.key}"]
      conditions = []
    },
    {
      sid    = "WriteBucket"
      effect = "Allow"
      actions = [
        "s3:PutObject",
        "s3:PutObjectVersionAcl",
        "s3:PutObjectAcl",
        "s3:GetObjectAcl",
        "s3:GetObject",
        "s3:GetObjectVersionAcl",
        "s3:GetObjectVersion"
      ]
      resources  = ["arn:aws:s3:::${each.key}/*"]
      conditions = []
    },
    # TODO: move this out so it's not duplicated
    {
      sid    = "ListBuckets"
      effect = "Allow"
      actions = [
        "s3:ListAllMyBuckets",
        "s3:HeadBucket"
      ]
      resources  = ["*"]
      conditions = []
    }
  ]
}

// TODO: deprecate this
module "app_bucket_policy_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = ["s3"]
  context    = module.this.context
}

// TODO: deprecate this
resource "aws_iam_policy" "app_bucket_iam_policy" {
  for_each    = toset(var.external_app_buckets)
  path        = "/"
  description = format("Allow ECS tasks access to S3 bucket %s required by the application", each.key)
  policy      = module.app_bucket_iam_policy[each.key].json
}

module "frontend_web" {
  source  = "cloudposse/cloudfront-s3-cdn/aws"
  version = "0.95.0"

  enabled = module.this.enabled && var.create_frontend_website

  # Use S3 origin
  website_enabled                    = false
  allow_ssl_requests_only            = true
  block_origin_public_access_enabled = true

  # For SPA routing - use CloudFront error handling
  custom_error_response = [
    {
      error_caching_min_ttl = 0
      error_code            = "404"
      response_code         = "200"
      response_page_path    = "/index.html"
    }
  ]

  # DNS/SSL
  parent_zone_id      = var.hosted_zone_id
  aliases             = [local.frontend_fqdn]
  dns_alias_enabled   = true
  acm_certificate_arn = var.cdn_certificate_arn

  deployment_principal_arns = {
    # Role -> prefix
    # Allow codebuild to deploy files to S3, with no prefix restriction
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${module.ecs_codepipeline.codebuild_role_id}" = [""]
  }

  # only built assets should be in this bucket
  versioning_enabled   = false
  origin_force_destroy = true

  context = module.this.context
}

###
# SSM parameter store values for exposing data to other modules/services

resource "aws_ssm_parameter" "ssm_param_frontend_bucket" {
  count       = module.this.enabled && var.create_frontend_website ? 1 : 0
  name        = "/${module.this.namespace}/${module.this.stage}/${module.this.environment}/build/FRONTEND_BUCKET"
  description = "Frontend bucket name"
  type        = "String"
  value       = module.frontend_web.s3_bucket
  tags        = module.this.tags
}

resource "aws_ssm_parameter" "ssm_param_app_fqdn" {
  count       = module.this.enabled && var.create_frontend_website ? 1 : 0
  name        = "/${module.this.namespace}/${module.this.stage}/${module.this.environment}/app/APP_FQDN"
  description = "Frontend bucket name"
  type        = "String"
  value       = module.frontend_web.s3_bucket
  tags        = module.this.tags
}
