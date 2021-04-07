// CloudWatch Log Group retention for CodeBuild and ECS Logs

module "label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.19.2"
  namespace  = var.namespace
  name       = var.app
  stage      = var.stage
  delimiter  = var.delimiter
  attributes = var.attributes
  tags       = var.tags
}

resource "null_resource" "ecs_log_retention" {
  for_each = {
    for k, v in var.ecs_log_groups :
    k => v
    if contains(var.log_groups_to_process, k)
  }

  provisioner "local-exec" {
    command = "aws logs put-retention-policy --log-group-name ${each.value} --retention-in-days ${var.ecs_log_group_retention_days}"
  }
}

resource "null_resource" "codebuild_log_retention" {
  provisioner "local-exec" {
    command = "aws logs put-retention-policy --log-group-name /aws/codebuild/${module.label.id}-build --retention-in-days ${var.codebuild_log_group_retention_days}"
  }
}
