locals {
  aws_region = var.aws_region != null ? var.aws_region : data.aws_region.current.name
}

data "aws_region" "current" {}

resource "null_resource" "log_retention" {
  for_each = var.log_groups
  provisioner "local-exec" {
    command = "aws logs put-retention-policy --region ${local.aws_region} --log-group-name ${each.value.log_group_name} --retention-in-days ${each.value.retention_days}"
  }
}
