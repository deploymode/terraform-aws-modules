locals {
  secrets = var.secrets_file != null ? [
    for secret in jsondecode(file(var.secrets_file)) : {
      for k, v in secret : k => v # format("{{resolve:ssm-secure:/${module.this.namespace}/${module.this.stage}/${module.this.environment}/app/%s}}", k)
    }
  ] : []

  queue_env_vars = var.queue_name != "" ? {
    SQS_QUEUE  = var.queue_name
    SQS_REGION = var.region
    SQS_PREFIX = "https://sqs.${var.region}.amazonaws.com/${data.aws_caller_identity.current.account_id}"
  } : {}
}

data "aws_caller_identity" "current" {}

module "elastic_beanstalk_application" {
  source  = "cloudposse/elastic-beanstalk-application/aws"
  version = "0.11.1"

  description = var.description

  context = module.this.context
}

data "aws_vpc" "default" {
  id = var.vpc_id
}

module "elastic_beanstalk_environment" {
  source  = "cloudposse/elastic-beanstalk-environment/aws"
  version = "0.46.0"

  name = coalesce(var.environment_name, module.this.name)

  description                = var.description
  region                     = var.region
  availability_zone_selector = var.availability_zone_selector
  dns_zone_id                = var.dns_zone_id
  dns_subdomain              = var.dns_subdomain

  wait_for_ready_timeout             = var.wait_for_ready_timeout
  elastic_beanstalk_application_name = module.elastic_beanstalk_application.elastic_beanstalk_application_name
  environment_type                   = var.environment_type
  loadbalancer_type                  = var.loadbalancer_type
  elb_scheme                         = var.elb_scheme
  tier                               = var.tier
  version_label                      = var.version_label
  force_destroy                      = var.force_destroy

  instance_type    = var.instance_type
  root_volume_size = var.root_volume_size
  root_volume_type = var.root_volume_type

  autoscale_min             = var.autoscale_min
  autoscale_max             = var.autoscale_max
  autoscale_measure_name    = var.autoscale_measure_name
  autoscale_statistic       = var.autoscale_statistic
  autoscale_unit            = var.autoscale_unit
  autoscale_lower_bound     = var.autoscale_lower_bound
  autoscale_lower_increment = var.autoscale_lower_increment
  autoscale_upper_bound     = var.autoscale_upper_bound
  autoscale_upper_increment = var.autoscale_upper_increment

  vpc_id               = var.vpc_id
  loadbalancer_subnets = var.public_subnet_ids
  application_subnets  = var.private_subnet_ids

  loadbalancer_certificate_arn = var.loadbalancer_certificate_arn
  loadbalancer_ssl_policy      = var.loadbalancer_ssl_policy

  allow_all_egress = true

  additional_security_group_rules = var.allowed_inbound_security_groups

  rolling_update_enabled  = var.rolling_update_enabled
  rolling_update_type     = var.rolling_update_type
  updating_min_in_service = var.updating_min_in_service
  updating_max_batch      = var.updating_max_batch

  healthcheck_url    = var.healthcheck_url
  enable_stream_logs = var.enable_stream_logs
  application_port   = var.application_port

  # https://docs.aws.amazon.com/elasticbeanstalk/latest/platforms/platforms-supported.html
  # https://docs.aws.amazon.com/elasticbeanstalk/latest/platforms/platforms-supported.html#platforms-supported.docker
  solution_stack_name = var.solution_stack_name

  additional_settings = var.additional_settings
  env_vars            = merge(var.env_vars, local.queue_env_vars, local.secrets...)

  extended_ec2_policy_document = jsonencode(
    {
      "Version"   = "2012-10-17"
      "Statement" = flatten(concat(values({ for i, v in values(var.ec2_policy_documents) : "Statement${i}" => jsondecode(v).Statement })))
    }
  )
  # join("", values(var.ec2_policy_documents))
  prefer_legacy_ssm_policy     = false
  prefer_legacy_service_policy = false
  scheduled_actions            = var.scheduled_actions

  context = module.this.context
}
