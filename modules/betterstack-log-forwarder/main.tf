module "log_forwarder" {
  source = "git::https://github.com/deploymode/terraform-betterstack-cloudwatch-logs.git?ref=tags/0.1.2"

  better_stack_token       = var.better_stack_token
  better_stack_ingest_host = var.better_stack_ingest_host

  timeout = var.lambda_timeout
  memory_size = var.lambda_memory_size

  log_group_names = var.log_group_names

  context = module.this.context
}