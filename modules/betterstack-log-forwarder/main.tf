module "log_forwarder" {
  source = "git::https://github.com/deploymode/terraform-betterstack-cloudwatch-logs.git?ref=tags/0.2.0"

  artefact_filename          = var.artefact_filename
  artefact_s3_bucket         = var.artefact_s3_bucket
  artefact_s3_key            = var.artefact_s3_key
  artefact_s3_object_version = var.artefact_s3_object_version

  lambda_runtime               = var.lambda_runtime
  lambda_handler               = var.lambda_handler
  lambda_architectures         = var.lambda_architectures
  lambda_environment_variables = var.lambda_environment_variables

  better_stack_token       = var.better_stack_token
  better_stack_ingest_host = var.better_stack_ingest_host

  timeout                        = var.lambda_timeout
  memory_size                    = var.lambda_memory_size
  reserved_concurrent_executions = var.lambda_reserved_concurrency
  maximum_retry_attempts         = var.lambda_maximum_retry_attempts

  cloudwatch_logs_retention_in_days = var.lambda_log_retention_in_days

  log_group_names = var.log_group_names
  filter_pattern  = var.filter_pattern

  context = module.this.context
}
