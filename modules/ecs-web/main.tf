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
  app_fqdn = join(".", [var.app_dns_name, var.domain_name])

  image_names_map = {
    "nginx"      = module.nginx_image_label.id
    "php"        = module.php-fpm_image_label.id
    "monitoring" = module.monitoring_image_label.id
  }

  log_groups = {
    nginx      = "/ecs/${module.container_label.id}/${local.image_names_map.nginx}"
    php        = "/ecs/${module.container_label.id}/${local.image_names_map.php}"
    monitoring = "/ecs/${module.container_label.id}/${local.image_names_map.monitoring}"
  }

  queue_env_vars = var.queue_name != "" ? [
    {
      name  = "SQS_QUEUE"
      value = var.queue_name
    },
    {
      name  = "SQS_REGION"
      value = var.aws_region
    },
    {
      name  = "SQS_PREFIX"
      value = "https://sqs.${var.aws_region}.amazonaws.com/${var.aws_account_id}"
    }
  ] : []

  redis_cache_env_vars = var.provision_redis_cache ? [
    {
      name  = "REDIS_HOST"
      value = format("tls://%s", module.redis.endpoint)
    }
  ] : []

  dynamodb_cache_env_vars = var.provision_dynamodb_cache ? [
    {
      name  = "DYNAMODB_CACHE_TABLE"
      value = module.dynamodb.table_name
    },
    # {
    #   name  = "DYNAMODB_ENDPOINT"
    #   value = module.dynamodb.table_name
    # },
  ] : []
}

// ECR Registry/Repo
module "ecr" {
  source       = "cloudposse/ecr/aws"
  version      = "0.32.3"
  use_fullname = true
  image_names = [
    local.image_names_map.nginx,
    local.image_names_map.php
  ]
  image_tag_mutability    = "MUTABLE"
  enable_lifecycle_policy = true
  max_image_count         = var.ecr_max_image_count
  context                 = module.this.context
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
  essential                = true
  readonly_root_filesystem = false
  environment              = var.container_environment_nginx
  secrets                  = var.container_ssm_secrets_nginx

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
  container_depends_on = var.monitoring_image_name != "" && var.monitoring_container_dependency ? [{
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
    local.dynamodb_cache_env_vars,
    local.redis_cache_env_vars,
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
  enabled    = var.monitoring_image_name != null
  context    = module.container_label.context
}

module "container_monitoring" {
  source                       = "cloudposse/ecs-container-definition/aws"
  version                      = "0.58.1"
  count                        = var.monitoring_image_name != null ? 1 : 0
  container_name               = module.monitoring_container_label.id
  container_image              = var.monitoring_image_name
  container_memory             = var.monitoring_container_memory
  container_memory_reservation = var.monitoring_container_memory_reservation
  container_cpu                = var.monitoring_container_cpu
  start_timeout                = var.container_start_timeout
  stop_timeout                 = var.container_stop_timeout
  # Task will stop if this container fails
  essential                = false
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
  source  = "cloudposse/alb/aws"
  version = "0.32.0"
  # source             = "git::https://github.com/joe-niland/terraform-aws-alb.git?ref=fix-access-logs-disabled"
  vpc_id             = var.vpc_id
  security_group_ids = var.alb_security_group_ids
  subnet_ids         = var.public_subnet_ids
  target_group_name  = module.this.id
  # target_group_port                       = var.target_group_port
  internal              = false
  http_port             = var.http_port
  https_port            = var.https_port
  http_enabled          = var.http_enabled
  https_enabled         = var.https_enabled
  http_redirect         = var.http_to_https_redirect
  health_check_path     = var.alb_healthcheck_path
  health_check_timeout  = var.alb_healthcheck_timeout
  health_check_interval = var.alb_healthcheck_interval
  certificate_arn       = var.certificate_arn
  access_logs_enabled   = false
  # access_logs_s3_bucket_id                = ""
  alb_access_logs_s3_bucket_force_destroy = true
  cross_zone_load_balancing_enabled       = true
  http2_enabled                           = true
  deletion_protection_enabled             = false
  context                                 = module.alb_label.context
}

module "ecs_task" {
  source  = "cloudposse/ecs-alb-service-task/aws"
  version = "0.63.1"
  context = module.this.context
  # attributes             = compact(concat(module.this.attributes, ["service"]))
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
  container_definition_json = jsonencode(
    concat([
      module.container_nginx.json_map_object,
      module.container_php-fpm.json_map_object
      ],
      var.monitoring_image_name != null ?
      [module.container_monitoring[0].json_map_object] : null
    )
  )
  ecs_cluster_arn              = var.ecs_cluster_arn
  capacity_provider_strategies = var.ecs_capacity_provider_strategies
  launch_type                  = var.ecs_launch_type
  platform_version             = var.ecs_platform_version
  vpc_id                       = var.vpc_id
  subnet_ids                   = var.private_subnet_ids
  task_policy_arns = concat(
    var.ecs_task_policy_arns,
    aws_iam_policy.email_policy.*.arn,
    [for v in aws_iam_policy.app_bucket_iam_policy : v.arn]
  )
  exec_enabled                   = var.ecs_enable_exec
  ignore_changes_task_definition = var.ecs_ignore_changes_task_definition

  network_mode     = var.ecs_network_mode
  assign_public_ip = var.assign_public_ip
  propagate_tags   = "TASK_DEFINITION"
  # deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  # deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_controller_type         = "ECS"
  circuit_breaker_deployment_enabled = var.ecs_circuit_breaker_deployment_enabled
  circuit_breaker_rollback_enabled   = var.ecs_circuit_breaker_rollback_enabled

  desired_count = var.ecs_task_desired_count
  task_memory   = var.ecs_task_memory
  task_cpu      = var.ecs_task_cpu


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


resource "aws_route53_record" "default" {
  count   = (var.hosted_zone_id != "" && var.create_alb_dns_record) ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = local.app_fqdn
  type    = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }
}

locals {
  app_cache_behavior = {
    viewer_protocol_policy      = "redirect-to-https"
    cached_methods              = ["GET", "HEAD"]
    allowed_methods             = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    default_ttl                 = 60
    min_ttl                     = 0
    max_ttl                     = 86400
    compress                    = true
    target_origin_id            = module.this.id # module.alb_label.id # .alb_dns_name #  join("", aws_route53_record.default.*.fqdn)
    forward_cookies             = "all"
    forward_header_values       = ["*"]
    forward_query_string        = true
    lambda_function_association = []
    function_association        = []
    cache_policy_id             = ""
    origin_request_policy_id    = ""
  }
}

module "cdn" {
  source  = "cloudposse/cloudfront-cdn/aws"
  version = "0.22.0"
  enabled = module.this.enabled && var.use_cdn

  aliases                         = [local.app_fqdn]
  origin_domain_name              = module.alb.alb_dns_name
  origin_protocol_policy          = "match-viewer"
  viewer_protocol_policy          = "redirect-to-https"
  viewer_minimum_protocol_version = var.cdn_viewer_min_protocol_version
  parent_zone_name                = var.domain_name
  default_root_object             = ""
  acm_certificate_arn             = var.cdn_certificate_arn
  forward_cookies                 = "all" #"whitelist"
  # forward_cookies_whitelisted_names = ["comment_author_*", "comment_author_email_*", "comment_author_url_*", "wordpress_logged_in_*", "wordpress_test_cookie", "wp-settings-*"]
  forward_headers      = ["Host", "Origin", "Referer", "CloudFront-Forwarded-Proto", "Access-Control-Request-Headers", "Access-Control-Request-Method"]
  forward_query_string = true
  default_ttl          = var.cdn_default_ttl
  min_ttl              = var.cdn_min_ttl
  max_ttl              = var.cdn_max_ttl
  compress             = true
  cached_methods       = ["GET", "HEAD", "OPTIONS"]
  allowed_methods      = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
  price_class          = "PriceClass_All"
  logging_enabled      = var.cdn_logging_enabled

  ordered_cache = [
    merge(local.app_cache_behavior, tomap({ "path_pattern" = "*" })),
    #   # merge(local.wp_nocache_behavior, map("path_pattern", "wp-login.php")),
    #   # merge(local.wp_nocache_behavior, map("path_pattern", "wp-signup.php")),
    #   # merge(local.wp_nocache_behavior, map("path_pattern", "wp-trackback.php")),
    #   # merge(local.wp_nocache_behavior, map("path_pattern", "wp-cron.php")),
    #   # merge(local.wp_nocache_behavior, map("path_pattern", "xmlrpc.php"))
  ]

  context = module.this.context
}

// CodePipeline

module "ecs_codepipeline" {
  # source = "git::https://github.com/joe-niland/terraform-aws-ecs-codepipeline.git?ref=support-type-attr-in-codebuild-env"
  source                  = "cloudposse/ecs-codepipeline/aws"
  version                 = "0.28.1"
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
  environment_variables = concat(var.codepipeline_environment_variables, [
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
  github_oauth_token    = ""
  github_webhooks_token = ""
  codebuild_vpc_config  = var.codebuild_vpc_config
}

module "codepipeline_notifications" {
  source  = "kjagiello/codepipeline-slack-notifications/aws"
  version = "1.1.5"

  count = (module.this.enabled && var.codepipeline_slack_notification_webhook_url == "") ? 0 : 1

  name           = "web" # module.this.id
  namespace      = module.this.namespace
  stage          = module.this.stage
  attributes     = [module.this.environment]
  slack_url      = var.codepipeline_slack_notification_webhook_url
  slack_channel  = var.codepipeline_slack_notification_channel
  event_type_ids = var.codepipeline_slack_notification_event_ids
  codepipelines = [
    module.ecs_codepipeline.codepipeline_resource
  ]
}

// Allow pull permission to CodeBuild

resource "aws_iam_role_policy_attachment" "codebuild" {
  count      = module.this.enabled ? 1 : 0
  role       = module.ecs_codepipeline.codebuild_role_id
  policy_arn = join("", aws_iam_policy.codebuild.*.arn)
}

# Allow Codebuild to read/write from S3 buckets
resource "aws_iam_role_policy_attachment" "codebuild_app_bucket" {
  # count      = module.this.enabled && length(var.external_app_buckets) > 0 ? 1 : 0
  for_each   = toset(var.external_app_buckets)
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
  source                 = "cloudposse/elasticache-redis/aws"
  version                = "0.40.1"
  enabled                = (module.this.enabled && var.provision_redis_cache)
  attributes             = compact(concat(module.this.attributes, ["cache"]))
  availability_zones     = var.redis_availability_zones
  zone_id                = var.hosted_zone_id
  vpc_id                 = var.vpc_id
  security_group_enabled = true
  security_group_rules = [
    {
      type                     = "egress"
      from_port                = 0
      to_port                  = 65535
      protocol                 = "-1"
      cidr_blocks              = ["0.0.0.0/0"]
      source_security_group_id = null
      description              = "Allow all outbound traffic"
    },
    {
      type                     = "ingress"
      from_port                = 6379
      to_port                  = 6379
      protocol                 = "-1"
      cidr_blocks              = []
      source_security_group_id = module.ecs_task.service_security_group_id
      description              = "Allow all inbound traffic from ECS service Security Group"
    },
    {
      type                     = "ingress"
      from_port                = 6379
      to_port                  = 6379
      protocol                 = "-1"
      cidr_blocks              = []
      source_security_group_id = join("", aws_security_group.redis_allowed.*.id)
      description              = "Allow all inbound traffic from generic Redis access Security Group"
    },
  ]
  subnets                    = var.private_subnet_ids
  cluster_mode_enabled       = var.redis_cluster_mode_enabled
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

module "redis_sg_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = ["redis", "allowed"]
  enabled    = module.this.enabled && var.provision_redis_cache
  context    = module.this.context
}

resource "aws_security_group" "redis_allowed" {
  count = module.this.enabled && var.provision_redis_cache ? 1 : 0

  name        = module.redis_sg_label.id
  description = "Services which need Redis access can be assigned this security group"
  vpc_id      = var.vpc_id
  tags        = module.this.tags
}

resource "aws_security_group_rule" "redis_egress" {
  count             = module.this.enabled && var.provision_redis_cache ? 1 : 0
  description       = "Allow all egress traffic"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = join("", aws_security_group.redis_allowed.*.id)
}

// DynamoDB Cache
module "dynamodb" {
  source                        = "cloudposse/dynamodb/aws"
  version                       = "0.25.2"
  enabled                       = (module.this.enabled && var.provision_dynamodb_cache)
  hash_key                      = "key"
  enable_autoscaler             = false
  enable_point_in_time_recovery = false
  billing_mode                  = "PAY_PER_REQUEST"
  ttl_attribute                 = var.dynamodb_cache_ttl_attribute
  context                       = module.this.context
}

data "aws_iam_policy_document" "dynamodb" {
  count = (module.this.enabled && var.provision_dynamodb_cache) ? 1 : 0

  # Allow ECS task to access DynamoDB cache table
  statement {
    sid = ""

    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:ConditionCheckItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:GetItem",
      "dynamodb:UpdateItem"
    ]

    resources = [
      module.dynamodb.table_arn
    ]

    effect = "Allow"
  }
}

module "dynamodb_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = ["dynamodb"]
  context    = module.this.context
}

resource "aws_iam_policy" "dynamodb_access_policy" {
  count       = (module.this.enabled && var.provision_dynamodb_cache) ? 1 : 0
  name        = module.dynamodb_label.id
  path        = "/"
  description = "Allows access to DynamoDB table for app cache"
  policy      = join("", data.aws_iam_policy_document.dynamodb.*.json)
}

resource "aws_iam_role_policy_attachment" "ecs_task_dynamodb" {
  count      = (module.this.enabled && var.provision_dynamodb_cache) ? 1 : 0
  role       = module.ecs_task.task_role_name
  policy_arn = join("", aws_iam_policy.dynamodb_access_policy.*.arn)
}

// Bucket access
module "app_bucket_iam_policy" {
  source  = "cloudposse/iam-policy/aws"
  version = "0.2.1"

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

module "app_bucket_policy_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = ["s3"]
  context    = module.this.context
}

resource "aws_iam_policy" "app_bucket_iam_policy" {
  for_each    = toset(var.external_app_buckets)
  path        = "/"
  description = format("Allow ECS tasks access to S3 bucket %s required by the application", each.key)
  policy      = module.app_bucket_iam_policy[each.key].json
}
