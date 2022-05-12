resource "null_resource" "log_retention" {
  for_each = var.log_groups
  provisioner "local-exec" {
    command = "aws logs put-retention-policy --log-group-name ${each.value.log_group_name} --retention-in-days ${each.value.retention_days}"
  }
}
