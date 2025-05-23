module "log_forwarder" {
  source = "git::https://github.com/deploymode/terraform-betterstack-cloudwatch-logs.git?ref=tags/0.1.1"

  better_stack_token       = var.better_stack_token
  better_stack_ingest_host = var.better_stack_ingest_host

  log_group_names = var.log_group_names

  context = module.this.context
}