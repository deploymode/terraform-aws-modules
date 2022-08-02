locals {
  secrets = var.secrets_file != null ? [
    for secret in jsondecode(file(var.secrets_file)) : {
      for k, v in secret : k => v # format("{{resolve:ssm-secure:/${module.this.namespace}/${module.this.stage}/${module.this.environment}/app/%s}}", k)
    }
  ] : []

  queue_enabled = var.queue_name != "" && var.queue_name != null

  # For Laravel to access the queue
  queue_env_vars = local.queue_enabled ? {
    SQS_QUEUE  = var.queue_name
    SQS_REGION = var.region
    SQS_PREFIX = "https://sqs.${var.region}.amazonaws.com/${data.aws_caller_identity.current.account_id}"
  } : {}

  # For ElasticBeanstalk worker tier
  additional_settings_worker = local.queue_enabled ? [
    {
      namespace = "aws:elasticbeanstalk:sqsd"
      name      = "WorkerQueueURL"
      value     = "https://sqs.${var.region}.amazonaws.com/${data.aws_caller_identity.current.account_id}/${var.queue_name}"
    },
    {
      namespace = "aws:elasticbeanstalk:sqsd"
      name      = "HttpPath"
      value     = var.queue_http_url

    }
  ] : []
}

data "aws_caller_identity" "current" {}

module "ssh_key_pair" {
  source  = "cloudposse/key-pair/aws"
  version = "0.18.3"

  enabled = module.this.enabled && var.create_key_pair

  ssh_public_key_path   = var.ssh_key_path
  generate_ssh_key      = "true"
  private_key_extension = ".pem"
  public_key_extension  = ".pub"

  context = module.this.context
}

module "elastic_beanstalk_application" {
  source  = "cloudposse/elastic-beanstalk-application/aws"
  version = "0.11.1"

  description = var.description

  appversion_lifecycle_service_role_arn      = var.appversion_lifecycle_service_role_arn
  appversion_lifecycle_max_count             = var.appversion_lifecycle_max_count
  appversion_lifecycle_delete_source_from_s3 = var.appversion_lifecycle_delete_source_from_s3

  context = module.this.context
}

data "aws_vpc" "default" {
  id = var.vpc_id
}

module "elastic_beanstalk_environment" {
  source  = "cloudposse/elastic-beanstalk-environment/aws"
  version = "0.47.0"

  for_each = var.environment_settings

  attributes = [each.value.tier]

  description                = var.description
  region                     = var.region
  availability_zone_selector = var.availability_zone_selector
  dns_zone_id                = var.dns_zone_id
  dns_subdomain              = var.dns_subdomain

  elastic_beanstalk_application_name = module.elastic_beanstalk_application.elastic_beanstalk_application_name

  associated_security_group_ids        = var.associated_security_group_ids
  security_group_create_before_destroy = true

  wait_for_ready_timeout = var.wait_for_ready_timeout

  healthcheck_url                = each.value.tier == "WebServer" ? var.healthcheck_url : ""
  deployment_ignore_health_check = var.deployment_ignore_health_check

  environment_type  = each.value.environment_type # var.environment_type
  tier              = each.value.tier
  loadbalancer_type = each.value.environment_type == "LoadBalanced" ? var.loadbalancer_type : null
  elb_scheme        = each.value.environment_type == "LoadBalanced" ? var.elb_scheme : null
  application_port  = each.value.tier == "WebServer" ? var.application_port : null
  version_label     = var.version_label
  force_destroy     = var.force_destroy

  instance_type    = var.instance_type
  root_volume_size = var.root_volume_size
  root_volume_type = var.root_volume_type

  enable_spot_instances                      = each.value.enable_spot_instances
  spot_fleet_on_demand_base                  = each.value.enable_spot_instances ? each.value.spot_fleet_on_demand_base : 0
  spot_fleet_on_demand_above_base_percentage = each.value.enable_spot_instances ? each.value.spot_fleet_on_demand_above_base_percentage : -1
  spot_max_price                             = each.value.enable_spot_instances ? each.value.spot_max_price : -1

  keypair = var.create_key_pair ? module.ssh_key_pair.key_name : ""

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
  loadbalancer_subnets = each.value.environment_type == "LoadBalanced" ? var.public_subnet_ids : []
  application_subnets  = var.private_subnet_ids

  loadbalancer_certificate_arn = each.value.environment_type == "LoadBalanced" ? var.loadbalancer_certificate_arn : null
  loadbalancer_ssl_policy      = each.value.environment_type == "LoadBalanced" ? var.loadbalancer_ssl_policy : null

  allow_all_egress = true

  additional_security_group_rules = var.allowed_inbound_security_groups

  rolling_update_enabled  = var.rolling_update_enabled
  rolling_update_type     = var.rolling_update_type
  updating_min_in_service = var.updating_min_in_service
  updating_max_batch      = var.updating_max_batch

  enable_stream_logs = var.enable_stream_logs

  # https://docs.aws.amazon.com/elasticbeanstalk/latest/platforms/platforms-supported.html
  # https://docs.aws.amazon.com/elasticbeanstalk/latest/platforms/platforms-supported.html#platforms-supported.docker
  solution_stack_name = var.solution_stack_name

  additional_settings = concat(
    each.value.tier == "Worker" ? local.additional_settings_worker : [],
    var.additional_settings
  )
  env_vars = merge(var.env_vars, local.queue_env_vars, each.value.env_vars, local.secrets...)

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
